#!/usr/bin/env bash

fastq_files_path=$1
out_path=$2

if [[ -z $out_path ]]; then
	echo No Output Path provided.
	echo Please provide an output path
	exit 1
fi

echo Processing FASTQ files through FASTP
echo Run time logs are saved to ${out_path}/fastp_run_time.log


for r1 in $fastq_files_path/*R1.fastq.gz; do 
	st=$(date '+%s')

	r2=$(echo $r1 | sed 's/R1.fastq.gz/R2.fastq.gz/') 
	out_prefix=${out_path}/$(basename $r1 | sed 's/_R1.fastq.gz//')

	/mnt/e/softwares/fastp \
		-i $r1 \
		-I $r2 \
		-o ${out_prefix}_R1_trimmed.fastq.gz \
		-O ${out_prefix}_R2_trimmed.fastq.gz \
		-w 12 \
		-h ${out_prefix}_report.html \
		-j ${out_prefix}_report.json > /dev/null 2>&1

	et=$(date '+%s')
	echo FASTQ:$(realpath $out_prefix);Time Elapsed:$((et - st)) seconds >> ${out_path}/fastp_run_time.log
done
