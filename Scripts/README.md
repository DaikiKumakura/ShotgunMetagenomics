# ショットガンメタゲノム解析のスクリプト集

作業ディレクトリはデータを配置した `metagenome/`。各スクリプトは対応するコンテナ内で実行する。セットアップは[上位のREADME](../README.md)を参照。

| スクリプト | 入力 | 実行環境 | 主な出力 |
| --- | --- | --- | --- |
| `qc.sh` | `rawdata/*_1.fastq.gz` と対応する `_2.fastq.gz` | KneadData | `qc/` |
| `merged.sh` | 同上 | BBtools | `merged/*.fastq` |
| `qc_merged.sh` | `merged/*.fastq` | KneadData | `qc_merged/` |
| `profile.sh` | `qc_merged/*_kneaddata.fastq` | HUMAnN3 | `profile/`、結合した機能プロファイル表 |

`qc.sh` はpaired-end処理の経路。機能プロファイリングの経路は `merged.sh` → `qc_merged.sh` → `profile.sh`。QCには `ref/ref_db`、プロファイリングには上位READMEの参照データベースが必要。

`mag.sh` はこのリポジトリに存在しない。MAG構築手順は未完成。

2026-10-03に入力・ペア・参照DB・実行ファイルのチェックと失敗時停止を追加。空白を含むパスにも対応。出力ディレクトリが既存の場合は停止するため、新しい作業ディレクトリで実行する。`THREADS=4 bash qc.sh` のようにスレッド数を指定できる。中間ファイルは削除せず、profile.shは最終clean readsだけを選ぶ。実データを使った全工程は未検証。

出力prefixとsingle-end最終ファイルの命名は[使用中のKneadData 0.10.0ソース](https://github.com/biobakery/kneaddata/tree/0.10.0/kneaddata)に合わせている。
