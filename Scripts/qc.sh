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
indexes=(ref/ref_db*.bt2 ref/ref_db*.bt2l)
((${#indexes[@]} >= 6)) || fail "Missing Bowtie2 index ref/ref_db"
command -v kneaddata >/dev/null || fail "kneaddata is not on PATH"
[[ ! -e qc ]] || fail "qc/ already exists; use a fresh working directory"
mkdir qc
for f in "${files[@]}"; do
    r="${f%_1.fastq.gz}_2.fastq.gz"
    sample=${f##*/}; sample=${sample%_1.fastq.gz}
    kneaddata --input "$f" --input "$r" -db ref/ref_db --output qc/ --output-prefix "${sample}_kneaddata" -t "$threads" --bypass-trf
done
# Preserve intermediate reads; do not delete outputs from other samples.
