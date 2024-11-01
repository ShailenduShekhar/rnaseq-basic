input_dir=$1
output_dir=$2
ss=$3
exon=$4

for fasta in ${input_dir}/*fa; do
	fasta_basename=$(basename $fasta | sed 's/\(.*\)\.fa.*/\1/')
	echo Building HISAT2 index for $fasta_basename

	st=$(date '+%s')

	hisat2-build \
		--ss $ss \
		--exon $exon \
		-p 1 \
		$fasta \
		${output_dir}/${fasta_basename} > ${output_dir}/${fasta_basename}_stdout.txt 2>&1

	exit_code=$?
	if [[ $exit_code -eq 0 ]]; then
		echo Index ready for $fasta_basename
	else
		echo Index building failed for $fasta_basename
	fi

	et=$(date '+%s')
	echo "FASTA:${fasta_basename};Time Elapsed:$((et - st)) seconds" >> ${output_dir}/hisat_build_run_time.log
done
