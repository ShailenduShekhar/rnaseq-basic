#!/usr/bin/env bash

in_dir=$1
out_dir=$2
cpu=$3
logfile=$4

# defining the colors
highlight=$(get_color.py pink)
nc=$(get_color.py nc)
green=$(get_color.py green)
red=$(get_color.py red)

print_log() {
        echo -e [$(date '+%D %H:%M:%S')] [${highlight}Fastp${nc}] $1 | tee -a $logfile
}

print_log "Running FASTP with $cpu threads ..."
fastp_out=${out_dir}/fastp_results
mkdir -p $fastp_out

for r1 in $in_dir/*R1.fastq.gz; do
	st=$(date '+%s')

	r2=$(echo $r1 | sed 's/R1.fastq.gz/R2.fastq.gz/')
	out_prefix=${fastp_out}/$(basename $r1 | sed 's/_R1.fastq.gz//')

	fastp \
		-i $r1 \
		-I $r2 \
		-o ${out_prefix}_trimmed_R1.fastq.gz \
		-O ${out_prefix}_trimmed_R2.fastq.gz \
		-w $cpu \
		-h ${out_prefix}_report.html \
		-j ${out_prefix}_report.json > ${out_prefix}_fastp_stdout.txt 2>&1

	et=$(date '+%s')

	fastp_exit_code=$?
	if [[ $fastp_exit_code -eq 0 ]]; then
		print_log "Fastp ${green}successful${nc} for sample $(basename $out_prefix). Runtime: $((et - st)) s"
	else
		print_log "Fastp ${red}unsuccessful${nc} for sample $(basename $out_prefix). Check ${out_prefix}_fastp_stdout.txt."
	fi
done
