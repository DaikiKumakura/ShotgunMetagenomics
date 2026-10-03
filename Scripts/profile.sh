#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob
fail() { printf '%s\n' "$*" >&2; exit 1; }
threads=${THREADS:-24}
[[ "$threads" =~ ^[1-9][0-9]*$ ]] || fail "THREADS must be a positive integer"
files=(qc_merged/*_kneaddata.fastq)
((${#files[@]})) || fail "No final clean *_kneaddata.fastq inputs"
for f in "${files[@]}"; do [[ -s "$f" ]] || fail "Empty input: $f"; done
for db in ref_choco/chocophlan ref_uniref/uniref ref_map/utility_mapping; do
    [[ -d "$db" ]] || fail "Missing database directory: $db"
done
for tool in humann_config humann humann_join_tables humann_renorm_table; do
    command -v "$tool" >/dev/null || fail "$tool is not on PATH"
done
[[ ! -e profile ]] || fail "profile/ already exists; use a fresh working directory"
mkdir profile
humann_config --update database_folders nucleotide ref_choco/chocophlan
humann_config --update database_folders protein ref_uniref/uniref
humann_config --update database_folders utility_mapping ref_map/utility_mapping
for f in "${files[@]}"; do
    humann -i "$f" -o profile/ --threads "$threads"
done
# Retain HUMAnN temporary directories for diagnosis; never remove other runs.
for kind in genefamilies pathabundance pathcoverage; do
    humann_join_tables -i profile/ -o "profile/$kind.tsv" --file_name "$kind"
    [[ -s "profile/$kind.tsv" ]] || fail "Missing joined table: $kind"
done
humann_renorm_table --input profile/genefamilies.tsv --units cpm --output profile/genefamilies_cpm.tsv
humann_renorm_table --input profile/pathabundance.tsv --units cpm --output profile/pathabundance_cpm.tsv
