# ショットガンメタゲノム解析のスクリプト集

作業ディレクトリはデータを配置した `metagenome/`。各スクリプトは対応するコンテナ内で実行する。セットアップは[上位のREADME](../README.md)を参照。

| スクリプト | 入力 | 実行環境 | 主な出力 |
| --- | --- | --- | --- |
| `qc.sh` | `rawdata/*_1.fastq.gz` と対応する `_2.fastq.gz` | KneadData | `qc/` |
| `merged.sh` | 同上 | BBtools | `merged/*.fastq` |
| `qc_merged.sh` | `merged/*.fastq` | KneadData | `qc_merged/` |
| `profile.sh` | `qc_merged/*.fastq` | HUMAnN3 | `profile/`、結合した機能プロファイル表 |

`qc.sh` はpaired-end処理の経路。機能プロファイリングの経路は `merged.sh` → `qc_merged.sh` → `profile.sh`。QCには `ref/ref_db`、プロファイリングには上位READMEの参照データベースが必要。

`mag.sh` はこのリポジトリに存在しない。MAG構築手順は未完成。

2026-10-03に4本のBash構文確認を実施。実データを使ったコンテナ内での全工程は未検証。現在のスクリプトは入力の欠落や途中失敗を十分に検出しないため、各段階の終了状態と出力を確認してから次へ進む。
