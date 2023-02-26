#!/bin/bash

echo "====="
echo "quality control"
echo "====="

#bowtie2-build ref/*.fa -o ref/ref_db

mkdir qc_merged

for f in merged/*.fastq;
do
	#r=${f%_*}_2.fastq.gz
	base=${f##*/}
	sample=${base%_*}

	echo "====="
	echo "====="
	echo "====="
	echo ${sample}
	echo "====="
	echo "====="
	echo "====="

	kneaddata -i $f -db ref/ref_db --output qc_merged -t 24 --bypass-trf

	rm qc_merged/*.trimmed.fastq
	rm qc_merged/*.repeats.removed.fastq
	rm qc_merged/*.contam.fastq

done








