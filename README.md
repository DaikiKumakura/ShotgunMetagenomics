# ShotgunMetagenomics
This directory is the tutorial of shotgun metagenomics.  
And then, this tutorial is the only Japanese.  
So, if you want English explain, please ask me (https://daikikumakura.github.io/).  

---

このディレクトリではショットガンメタゲノム解析のチュートリアルになっています。  
基本要求として、PCにDockerがインストールされており、Dockerが動く状態です。  
主にDockerによる解析のため、PythonやRなどの言語をローカル上に入れる必要は無いです。  
（ただし解析した結果から図を作成する場合、その限りではありません）  
以下ではその解析チュートリアルを示します。  
何かあればお気軽にお尋ねください (https://daikikumakura.github.io/) 。

## コンセプト
可能な限り簡単で誰でも動かせる解析を目指します。  
そのため、少ないツールでショットガンメタゲノム解析を実行できるようにツールを絞っています。  
また、誰でも使用可能にするために、Dockerによる解析を想定しています。  
以下がこのチュートリアルで想定する対象者です。  
- ショットガンメタゲノム解析を動かしてみたい。
- 生データを手に入れたが、一貫した解析を動かす環境を構築していない。
- 多人数で同じショットガンメタゲノム解析をするための指標が欲しい。

## 要求
Dockerさえ入っていれば動かせるようにしています。  
また、解析の都合上ある程度のスペックがないと計算時間が大幅にかかることが予想されます。  

## 流れ
1. イメージのpull
2. デモデータなどのダウンロードとディレクトリの作成
3. ステップバイステップでの解析

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

# 解凍
gunzip *qz

# 解凍したものは「metagenome」ディレクトリの「rawdata」ディレクトリに格納
mkdir metagenome
mkdir metagenome/rawdata
mv *fastq metagenome/rawdata
```
- 宿主ゲノムデータ  
必要なデータをダウンロードする。  
今回の場合、ヒトゲノムのfastaファイルをダウンロードする。  
```
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
gunzip hg38.fa.gz

# 解凍したものは「metagenome」ディレクトリの「ref」ディレクトリに格納
mkdir metagenome/ref
mv *fa metagenome/ref
```
- 微生物データベース  
パンゲノム・酵素・代謝マップのデータベースをダウンロードする。  
```
humann_databases --download chocophlan full /metagenome/ref_choco --update-config yes
humann_databases --download uniref uniref90_diamond /metagenome/ref_uniref --update-config yes
humann_databases --download utility_mapping full /metagenome/ref_map --update-config yes
```

- スクリプトファイル  
Quality control、Taxonomic profiling、Construction MAGでそれぞれ使用するスクリプトをダウンロードする。  
```
wget --no-check-certificate https://github.com/DaikiKumakura/ShotgunMetagenomics/Scripts/merged.sh
wget --no-check-certificate https://github.com/DaikiKumakura/ShotgunMetagenomics/Scripts/qc_merged.sh
wget --no-check-certificate https://github.com/DaikiKumakura/ShotgunMetagenomics/Scripts/profile.sh
wget --no-check-certificate https://github.com/DaikiKumakura/ShotgunMetagenomics/Scripts/qc.sh
wget --no-check-certificate https://github.com/DaikiKumakura/ShotgunMetagenomics/Scripts/mag.sh
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
docker run -itv $(pwd):/home kumalpha/kneaddata
```
このコマンドによって、「/home」がそのまま「metagenome」のディレクトリになる。  
ここで解析を実行する。  

#### 3-1-2. 解析の実行(paired-end: metaWRAPに使用)
KneadDataによって、生データから宿主ゲノムリードを除去し、QCを行ってデータのクレンジングを実施する(以下、QCデータ)。  
このQCデータを用いて、その後の解析を実施する。  
  
まずは除去する宿主ゲノムをKneadDataが認識できるように以下のコマンドを打つ。  
ここでは2でダウンロードしたヒトゲノム「hg38.fa」を例に示す。  
```
bowtie2-build ref/hg38.fa -o ref/ref_db ref_db
```
このコマンドによって、「metagenome」ディレクトリの「ref」ディレクトリに格納されている「hg38.fa」をKneadDataが扱えるようなデータファイルにした。  
そして、そのデータファイルは「ref」の中に「ref_db」として格納されている。  
  
次にQCを実行する。  
実行に際して、2でダウンロードしたbashスクリプト「qc.sh」を実行するだけでOK。  
ただし、以下の点を確認すること。  
- 生データが「metagenome/raw」に格納されていること
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
docker run -itv $(pwd):/home kumalpha/bbtools
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
  
次に、QCする。
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
docker run -itv $(pwd):/home kumalpha/humann3
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
- genefamily.tsv
- pathabund.tsv
- pathcov.tsv

これらのtsvファイルは解析したすべてのサンプルを統合した結果になっている。  
この結果からさまざまな可視化や議論をしていく。  
  
この作業で3-2は終了。

---

### 3-3. Construction MAG
QCをしたデータを使用して解析をしていきます。  
使えるデータ全てを使って、微生物のゲノムを再構成(MAG)します。  
MAGはその後さまざまな解析に利用可能です。  
- パンゲノム解析
- 系統解析 etc.

**解析ツール**
- MetaWRAP



