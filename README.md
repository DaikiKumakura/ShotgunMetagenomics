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

#### 3-1-1. Dockerからイメージを起動
1でpullした「KneadData」を起動する。  
まずは2で作成した「metagenome」ディレクトリにてターミナルを起動。  
次に以下のコマンドを打って、KneadDataを起動させる。
```
docker run -itv $(pwd):/home kumalpha/kneaddata
```
このコマンドによって、「/home」がそのまま「metagenome」のディレクトリになる。  
ここで解析を実行する。  

#### 3-1-2. 解析の実行
KneadDataによって、生データから宿主ゲノムリードを除去し、QCを行ってデータのクレンジングを実施する(以下、QCしたデータ)。  
このQCしたデータを用いて、その後の解析を実施する。  
  
まずは除去する宿主ゲノムをKneadDataが認識できるように以下のコマンドを打つ。  
ここでは2でダウンロードしたヒトゲノム「hg38.fa」を例に示す。  
```
bowtie2-build ref/hg38.fa -o ref/ref_db ref_db_human
```

このコマンドによって、「metagenome」ディレクトリの「ref」ディレクトリに格納されている「hg38.fa」をKneadDataが扱えるようなデータファイルにした。  
そして、そのデータファイルは「ref」の中に「ref_db_human」として格納されている。  



### 3-2. Taxonomic Profiling
QCをしたデータを使用して解析をしていきます。  
まずはこのデータからどんな微生物がどれくらい存在していて、どんな酵素遺伝子を持っているかを見ていきます。  

**解析ツール**
- BBtools
- HUMAnN3


### 3-3. Construction MAG
QCをしたデータを使用して解析をしていきます。  
使えるデータ全てを使って、微生物のゲノムを再構成(MAG)します。  
MAGはその後さまざまな解析に利用可能です。  
- パンゲノム解析
- 系統解析 etc.

**解析ツール**
- MetaWRAP



