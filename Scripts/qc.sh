#!/bin/bash

echo "====="
echo "quality control"
echo "====="

#bowtie2-build ref/*.fa -o ref/ref_db

mkdir qc

for f in rawdata/*_1.fastq.gz;
do
	r=${f%_*}_2.fastq.gz
	base=${f##*/}
	sample=${base%_*}

	echo "====="
	echo "====="
	echo "====="
	echo ${sample}
	echo "====="
	echo "====="
	echo "====="

	kneaddata --input $f --input $r -db ref/ref_db --output qc/ -t 24 --bypass-trf

	rm qc/*_contam.fastq

	rm qc/*_unmatched_1.fastq
	rm qc/*_unmatched_2.fastq

	rm qc/*.trimmed.1.fastq
	rm qc/*.trimmed.2.fastq

	rm qc/*.single.1.fastq
	rm qc/*.single.2.fastq

done








