#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
fail() { printf '%s\n' "$*" >&2; exit 1; }
threads=${THREADS:-24}
[[ "$threads" =~ ^[1-9][0-9]*$ ]] || fail "THREADS must be a positive integer"
files=(merged/*.fastq)
((${#files[@]})) || fail "No merged FASTQ inputs"
for f in "${files[@]}"; do [[ -s "$f" ]] || fail "Empty input: $f"; done
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
[[ ! -e qc_merged ]] || fail "qc_merged/ already exists; use a fresh working directory"
mkdir qc_merged
for f in "${files[@]}"; do
    sample=${f##*/}; sample=${sample%.fastq}
    kneaddata -i "$f" -db ref/ref_db --output qc_merged --output-prefix "${sample}_kneaddata" -t "$threads" --bypass-trf
    [[ -s "qc_merged/${sample}_kneaddata.fastq" ]] || fail "No final clean reads for $sample"
done
# Intermediate reads are retained. profile.sh selects only final clean reads.
