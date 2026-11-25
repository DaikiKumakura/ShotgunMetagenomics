# ShotgunMetagenomics guide

**A Japanese hands-on tutorial for shotgun metagenomics with Docker: quality
control, host-read removal and functional profiling of gut metagenomes.**

The tutorial is written in Japanese. It runs every tool in a Docker container,
so nothing but Docker has to be installed. It downloads public human gut
metagenomes (ERR011347–ERR011349) and goes from raw reads to HUMAnN 3 gene
family and pathway tables.

> [!WARNING]
> The scripts check their inputs and stop on errors, and their control flow
> is tested, but the Docker images have not been rebuilt and the whole
> workflow has not been run on real data recently. The tutorial assumes older
> tool versions, and the MAG section is unfinished.

---

ショットガンメタゲノム解析のチュートリアルです。Dockerが動くPCがあれば、PythonやRをローカルに入れずに、生データからHUMAnN 3の機能プロファイルまで進められます（結果から図を作る場合は別途必要）。英語の説明が必要な場合は[サイト](https://daikikumakura.github.io/)からお尋ねください。

## ドキュメント

[必要なもの](#必要なもの) · [確認範囲](#確認範囲) · [全体の流れ](#全体の流れ)

## 全体の流れ

初めて実行する場合は、[必要なもの](#必要なもの)と[確認範囲](#確認範囲)を確認してから、下の番号付き手順を順に進めてください。

```text
  生データ（paired-end FASTQ）
        │  qc.sh           KneadData   宿主（ヒト）リードの除去とQC → qc/
        │  merged.sh       BBtools     paired-end を single-end に結合 → merged/
        │  qc_merged.sh    KneadData   結合したリードのQC → qc_merged/
        │  profile.sh      HUMAnN 3    機能プロファイリング → profile/
        ▼
  genefamilies.tsv · pathabundance.tsv · pathcoverage.tsv
```

| 段階 | スクリプト | コンテナ | 入力 | 出力 |
|---|---|---|---|---|
| 1. QC（paired-end） | `qc.sh` | `kumalpha/kneaddata` | `rawdata/*_1.fastq.gz`、`_2.fastq.gz` | `qc/` |
| 2. 結合 | `merged.sh` | `kumalpha/bbtools` | `rawdata/` | `merged/*.fastq` |
| 3. QC（single-end） | `qc_merged.sh` | `kumalpha/kneaddata` | `merged/*.fastq` | `qc_merged/` |
| 4. 機能プロファイリング | `profile.sh` | `kumalpha/humann3` | `qc_merged/*_kneaddata.fastq` | `profile/`（全サンプルを結合した表） |
| 5. MAG構築 | （未提供） | `kumalpha/metawrap-checkm` | — | 未完成 |

機能プロファイリングの経路は 2 → 3 → 4 です。1 は paired-end のQC結果を別途使う場合の経路です。各スクリプトの詳細は[`Scripts/README.md`](Scripts/README.md)にあります。

## 対象者

- ショットガンメタゲノム解析を一度動かしてみたい人
- 生データはあるが、一貫した解析環境をまだ作っていない人
- 複数人で同じ手順の解析をそろえたい人

ツールは最小限に絞っています。ここで使うツールは一例で、目的に応じて置き換えてください。

## 必要なもの

- Docker（Mac、またはWSL2上のUbuntuのターミナルで動かす想定）
- 宿主（ヒト）ゲノム hg38 と HUMAnN のデータベース（ChocoPhlAn、UniRef90、utility mapping）。合わせて数十GB規模のディスクが必要です
- 十分なメモリとCPU。スペックが低いと計算に長時間かかります

## 確認範囲

- 2026-09-27：ダウンロード先、圧縮ファイルの扱い、コンテナ内の作業場所など、手順の明らかな不整合を修正しました。
- 2026-10-03：入力・ペア・参照DB・実行ファイルの確認と、失敗時の停止を各スクリプトに追加しました。制御の流れを確かめるテスト（`python -m unittest -v`）は GitHub Actions でも実行しています。
- Dockerイメージのビルドと、実データでの全工程は未検証です。

---

## 1. イメージのpull

まずはDockerHub(https://hub.docker.com/) から、今回の解析で使用するイメージをダウンロード＆インストール(pull)します。
今回使用するツールは以下の4つです。
- KneadData
- BBtools
- HUMAnN3
- metaWRAP

それぞれのイメージのpullは以下です。
このコマンドをそれぞれコピペしてpullする。
```
docker pull kumalpha/kneaddata
docker pull kumalpha/bbtools
docker pull kumalpha/humann3
docker pull kumalpha/metawrap-checkm
```
これらはターミナル(Mac & Ubuntu (on WSL2))からできます。
pull後は以下のコマンドでイメージがローカル環境にあることを確認。
```
docker images
```

## 2. デモデータなどのダウンロードとディレクトリの作成

必要なデータは以下である。
- デモデータ
腸内細菌のショットガンメタゲノムデータをダウンロード
```
# それぞれ生データをダウンロード。
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011347/ERR011347_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011347/ERR011347_2.fastq.gz

wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011348/ERR011348_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011348/ERR011348_2.fastq.gz

wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011349/ERR011349_1.fastq.gz
wget ftp.sra.ebi.ac.uk/vol1/fastq/ERR011/ERR011349/ERR011349_2.fastq.gz

# 後続のスクリプトは .fastq.gz を入力に使うため、解凍しない
mkdir -p metagenome/rawdata
mv ERR01134[789]_[12].fastq.gz metagenome/rawdata/
```
- 宿主ゲノムデータ
必要なデータをダウンロードする。
今回の場合、ヒトゲノムのfastaファイルをダウンロードする。
```
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

# 解凍したものは「metagenome」ディレクトリの「ref」ディレクトリに格納
mkdir metagenome/ref
mv hg38.fa metagenome/ref/
```
- 微生物データベース
パンゲノム・酵素・代謝マップのデータベースをダウンロードする。ここまで作業したディレクトリから `metagenome` に移動し、HUMAnNコンテナを起動します。データベースのコマンドはコンテナ内で実行します。終了後は `exit` でホストへ戻ります。

```bash
cd metagenome
docker run --rm -it -v "$(pwd):/home" -w /home kumalpha/humann3 bash
```
```
humann_databases --download chocophlan full /home/ref_choco --update-config yes
humann_databases --download uniref uniref90_diamond /home/ref_uniref --update-config yes
humann_databases --download utility_mapping full /home/ref_map --update-config yes
```

- スクリプトファイル
Quality controlと機能プロファイリングで使用する4本をダウンロードする。`mag.sh` はこのリポジトリには含まれていません。以下は `metagenome` ディレクトリで実行します。
```
wget https://raw.githubusercontent.com/DaikiKumakura/ShotgunMetagenomics/main/Scripts/merged.sh
wget https://raw.githubusercontent.com/DaikiKumakura/ShotgunMetagenomics/main/Scripts/qc_merged.sh
wget https://raw.githubusercontent.com/DaikiKumakura/ShotgunMetagenomics/main/Scripts/profile.sh
wget https://raw.githubusercontent.com/DaikiKumakura/ShotgunMetagenomics/main/Scripts/qc.sh
```

## 3. ステップバイステップでの解析

ここでは、2で既にディレクトリ構造が要求するものになっていることを前提で進めます。
以下が解析の順序です。
1. Quality Control
2. Taxonomic Profiling
3. Construction MAG

今回使用する解析ツールはあくまでも一例です。
実際にはさまざまな解析ツールが存在しますので、適宜変更して利用してください。

---

### 3-1. Quality Control
ダウンロードしたデータは生データであり、さまざまなノイズが入ったデータです。
まずはデータを精製してより使いやすいデータにしていきます。

**解析ツール**
- KneadData
- BBtools

#### 3-1-1. Dockerからイメージを起動
1でpullした「KneadData」を起動する。
まずは2で作成した「metagenome」ディレクトリにてターミナルを起動。
次に以下のコマンドを打って、KneadDataを起動させる。
```
docker run --rm -it -v "$(pwd):/home" -w /home kumalpha/kneaddata
```
このコマンドによって、「/home」がそのまま「metagenome」のディレクトリになる。
ここで解析を実行する。初回は、コンテナ内で宿主ゲノムのインデックスを作成します。

```bash
bowtie2-build ref/hg38.fa ref/ref_db
```

#### 3-1-2. 解析の実行(paired-end: metaWRAPに使用)
KneadDataによって、生データから宿主ゲノムリードを除去し、QCを行ってデータのクレンジングを実施する(以下、QCデータ)。
このQCデータを用いて、その後の解析を実施する。

宿主ゲノムのインデックスは3-1-1で作成済みのものを使用します。
このコマンドによって、「metagenome」ディレクトリの「ref」ディレクトリに格納されている「hg38.fa」をKneadDataが扱えるようなデータファイルにした。
そして、そのデータファイルは「ref」の中に「ref_db」として格納されている。

次にQCを実行する。
実行に際して、2でダウンロードしたbashスクリプト「qc.sh」を実行するだけでOK。
ただし、以下の点を確認すること。
- 生データが「metagenome/rawdata」に格納されていること
- 宿主ゲノムデータ群が「metagenome/ref」に格納されていること
```
bash qc.sh
```
このコマンドによって、「metagenome/qc」という新たなディレクトリが作成される。
そして、そのディレクトリの中にQCされたデータが格納される。

#### 3-1-3-1. Dockerからイメージを起動(BBtools)
1でpullした「BBtools」を起動する。
まずは2で作成した「metagenome」ディレクトリにてターミナルを起動。
次に以下のコマンドを打って、BBtoolsを起動させる。
```
docker run --rm -it -v "$(pwd):/home" -w /home kumalpha/bbtools
```
このコマンドによって、「/home」がそのまま「metagenome」のディレクトリになる。
ここで解析を実行する。

#### 3-1-3-2. 解析の実行(single-end: HUMAnN3に使用)
生データは現在、paired-endである。
このままだとHUMAnN3にインプットできない。
そこで、「BBtools」を用いて、paired-end→single-endにする。
実行に際して、2でダウンロードしたbashスクリプト「merged.sh」を実行するだけでOK。
ただし、以下の点を確認すること。
- 生データが「metagenome/rawdata」に格納されていること
```
bash merged.sh
```
このコマンドによって、「metagenome/merged」という新たなディレクトリが作成される。
そして、そのディレクトリの中にsingle-end化した生データが格納される。

BBtoolsコンテナを `exit` で終了し、ホストの `metagenome` ディレクトリからKneadDataコンテナを再度起動してQCします。

```bash
docker run --rm -it -v "$(pwd):/home" -w /home kumalpha/kneaddata
```
実行に際して、「qc_merged.sh」を実行するだけでOK。
ただし、以下の点を確認すること。
- single-endの生データが「metagenome/merged」に格納されていること
- 宿主ゲノムデータ群が「metagenome/ref」に格納されていること
```
bash qc_merged.sh
```

この作業で3-1は終了。

---

### 3-2. Taxonomic Profiling
QCをしたデータを使用して解析をしていきます。
まずはこのデータからどんな微生物がどれくらい存在していて、どんな酵素遺伝子を持っているかを見ていきます。

**解析ツール**
- HUMAnN3

#### 3-2-1. Dockerからイメージを起動(HUMAnN3)
1でpullした「HUMAnN3」を起動する。
まずは2で作成した「metagenome」ディレクトリにてターミナルを起動。
次に以下のコマンドを打って、HUMAnN3を起動させる。
```
docker run --rm -it -v "$(pwd):/home" -w /home kumalpha/humann3
```
このコマンドによって、「/home」がそのまま「metagenome」のディレクトリになる。
ここで解析を実行する。

#### 3-2-2. 解析の実行(HUMAnN3)
次はHUMAnN3を実行して、サンプル内にどのような微生物がどの程度存在しているか、およびどのような酵素遺伝子をどの程度保有しているかを解析していく。
実行に際して、2でダウンロードしたbashスクリプト「profile.sh」を実行するだけでOK。
ただし、以下の点を確認すること。
- single-end化したQCデータが「metagenome/qc_merged」に格納されていること
- 各種データベースが「metagenome/ref_choco」、「metagenome/ref_uniref」、「metagenome/ref_map」に格納されていること
```
bash profile.sh
```
このコマンドによって、「metagenome/profile」という新たなディレクトリが作成される。
そして、そのディレクトリの中に以下のデータ群が格納される。
- genefamilies.tsv
- pathabundance.tsv
- pathcoverage.tsv

これらのtsvファイルは解析したすべてのサンプルを統合した結果になっている。
この結果からさまざまな可視化や議論をしていく。

この作業で3-2は終了。

---

### 3-3. Construction MAG（未完成）

この節の実行手順・スクリプトは未提供です。現時点で一連の解析が完結するものとして扱わないでください。
QCをしたデータを使用して解析をしていきます。
使えるデータ全てを使って、微生物のゲノムを再構成(MAG)します。
MAGはその後さまざまな解析に利用可能です。
- パンゲノム解析
- 系統解析 etc.

**解析ツール**
- metaWRAP

## スクリプトの安全な実行

入力・ペア・参照DBの欠落やコマンドの失敗は停止する。出力ディレクトリが既存の場合も停止する。中間ファイルを保存し、HUMAnNには最終clean reads (`*_kneaddata.fastq`)のみを渡す。`python -m unittest -v` は小規模な入力と代用コマンドで制御処理を検証する。GitHub Actionsでも実行するが、実データの生物学的結果は保証しない。

## 関連 / Related

- [Dockerfiles](https://github.com/DaikiKumakura/Dockerfiles): このチュートリアルで使うイメージの定義（未保守の旧定義を含む）
- [サイトの紹介ページ](https://daikikumakura.github.io/software/shotgunmetagenomics.html)

## Citation

Kumakura, D. *ShotgunMetagenomics* [Software]. [GitHub repository](https://github.com/DaikiKumakura/ShotgunMetagenomics).

## License

This project is licensed under MIT. See [LICENSE](LICENSE) for the license terms.
