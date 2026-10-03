#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
fail() { printf '%s\n' "$*" >&2; exit 1; }
threads=${THREADS:-24}
[[ "$threads" =~ ^[1-9][0-9]*$ ]] || fail "THREADS must be a positive integer"
files=(rawdata/*_1.fastq.gz)
((${#files[@]})) || fail "No paired FASTQ inputs in rawdata/"
for f in "${files[@]}"; do
    r="${f%_1.fastq.gz}_2.fastq.gz"
    [[ -s "$f" && -s "$r" ]] || fail "Missing or empty paired input: $f / $r"
done
index_ok=0
for extension in bt2 bt2l; do
    complete=1
    for suffix in 1 2 3 4 rev.1 rev.2; do
        [[ -s "ref/ref_db.$suffix.$extension" ]] || complete=0
    done
    if ((complete)); then index_ok=1; break; fi
done
((index_ok)) || fail "Missing or incomplete Bowtie2 index ref/ref_db"
command -v kneaddata >/dev/null || fail "kneaddata is not on PATH"
[[ ! -e qc ]] || fail "qc/ already exists; use a fresh working directory"
mkdir qc
for f in "${files[@]}"; do
    r="${f%_1.fastq.gz}_2.fastq.gz"
    sample=${f##*/}; sample=${sample%_1.fastq.gz}
    kneaddata --input "$f" --input "$r" -db ref/ref_db --output qc/ --output-prefix "${sample}_kneaddata" -t "$threads" --bypass-trf
done
# Preserve intermediate reads; do not delete outputs from other samples.
