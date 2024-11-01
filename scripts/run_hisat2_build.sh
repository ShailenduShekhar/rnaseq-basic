#!/usr/bin/bash


input_dir=$1
output_dir=$2
ss=$3
exon=$4
logfile=$5


# defining the colors
red="\033[0;31m"
blue="\033[01;34m"
bror="\033[0;33m"
nc="\033[0m"


print_log() {
	echo -e [$(date '+%D %H:%M:%S')] [${blue}hisat2_index_build${nc}] $1 | tee -a $logfile
}

for fasta in ${input_dir}/*fa; do
	fasta_basename=$(basename $fasta | sed 's/\(.*\)\.fa.*/\1/')
	print_log "Building HISAT2 index for $fasta_basename"

	st=$(date '+%s')

	hisat2-build \
		--ss $ss \
		--exon $exon \
		-p 1 \
		$fasta \
		${output_dir}/${fasta_basename} > ${output_dir}/${fasta_basename}_stdout.txt 2>&1

	exit_code=$?
	et=$(date '+%s')

	if [[ $exit_code -eq 0 ]]; then
		print_log "Index ready for $fasta_basename. Runtime: $((et - st)) s"
	else
		print_log "Index building failed for $fasta_basename"
	fi

	echo "FASTA:${fasta_basename};Time Elapsed:$((et - st)) seconds" >> ${output_dir}/hisat_build_run_time.log
done
