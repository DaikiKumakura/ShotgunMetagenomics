#!/bin/bash

echo "====="
echo "taxon profile"
echo "====="

mkdir profile

humann_config --update database_folders nucleotide ref_choco/chocophlan
humann_config --update database_folders protein ref_uniref/uniref
humann_config --update database_folders utility_mapping ref_map/utility_mapping

humann_config --update run_modes threads 24
humann_config --update run_modes verbose True

for f in qc_merged/*.fastq;
do
	base=${f##*/}
	sample=${base%_*}

	echo "====="
	echo ${sample}
	echo "====="

	humann -i $f -o profile/

	mv profile/*_humann_temp/*_metaphlan_bugs_list.tsv profile/
	rm -r profile/*_humann_temp/

done

humann_join_tables -i profile/ -o profile/genefamilies.tsv --file_name genefamilies
humann_join_tables -i profile/ -o profile/pathabundance.tsv --file_name pathabundance
humann_join_tables -i profile/ -o profile/pathcoverage.tsv --file_name pathcoverage

humann_renorm_table --input profile/genefamilies.tsv --units cpm --output profile/genefamilies_cpm.tsv
humann_renorm_table --input profile/pathabundance.tsv --units cpm --output profile/pathabundance_cpm.tsv


