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
command -v bbmerge.sh >/dev/null || fail "bbmerge.sh is not on PATH"
[[ ! -e merged ]] || fail "merged/ already exists; use a fresh working directory"
mkdir merged
for f in "${files[@]}"; do
    r="${f%_1.fastq.gz}_2.fastq.gz"
    sample=${f##*/}; sample=${sample%_1.fastq.gz}
    bbmerge.sh "in1=$f" "in2=$r" "out=merged/${sample}.fastq" "threads=$threads"
    [[ -s "merged/${sample}.fastq" ]] || fail "No merged reads for $sample"
done
