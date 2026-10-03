#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
fail() { printf '%s\n' "$*" >&2; exit 1; }
threads=${THREADS:-24}
[[ "$threads" =~ ^[1-9][0-9]*$ ]] || fail "THREADS must be a positive integer"
files=(merged/*.fastq)
((${#files[@]})) || fail "No merged FASTQ inputs"
for f in "${files[@]}"; do [[ -s "$f" ]] || fail "Empty input: $f"; done
indexes=(ref/ref_db*.bt2 ref/ref_db*.bt2l)
((${#indexes[@]} >= 6)) || fail "Missing Bowtie2 index ref/ref_db"
command -v kneaddata >/dev/null || fail "kneaddata is not on PATH"
[[ ! -e qc_merged ]] || fail "qc_merged/ already exists; use a fresh working directory"
mkdir qc_merged
for f in "${files[@]}"; do
    sample=${f##*/}; sample=${sample%.fastq}
    kneaddata -i "$f" -db ref/ref_db --output qc_merged --output-prefix "${sample}_kneaddata" -t "$threads" --bypass-trf
done
# Intermediate reads are retained. profile.sh selects only final clean reads.
