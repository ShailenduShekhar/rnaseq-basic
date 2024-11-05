#!/usr/bin/bash


input_dir=$1
output_dir=$2
annot_params=$3
logfile=$4

# defining the colors
highlight=$(get_color.py pink)
green=$(get_color.py green)
red=$(get_color.py red)
nc=$(get_color.py nc)

print_log() {
	echo -e [$(date '+%D %H:%M:%S')] [${highlight}hisat2-index-build${nc}] $1 | tee -a "$logfile"
}

for fasta in ${input_dir}/*fa; do
	fasta_basename=$(basename $fasta | sed 's/\(.*\)\.fa.*/\1/')
	print_log "Building HISAT2 index for $fasta_basename ..."

	st=$(date '+%s')

	hisat2-build ${annot_params} \
		-p 1 \
		$fasta \
		${output_dir}/${fasta_basename} > ${output_dir}/${fasta_basename}_stdout.txt 2>&1

	exit_code=$?
	et=$(date '+%s')

	if [[ $exit_code -eq 0 ]]; then
		print_log "Index building ${green}successful${nc} for $fasta_basename. Runtime: $((et - st)) s"
	else
		print_log "Index building ${red}failed${nc} for $fasta_basename"
	fi
done
