#!/bin/bash

echo "====="
echo "merged"
echo "====="

mkdir merged

for f in rawdata/*_1.fastq.gz;
do
	r=${f%_*}_2.fastq.gz
	base=${f##*/}
	sample=${base%_*}

	echo "====="
	echo ${sample}
	echo "====="

	bbmerge.sh in1=$f in2=$r out=merged/${sample}.fastq

done

