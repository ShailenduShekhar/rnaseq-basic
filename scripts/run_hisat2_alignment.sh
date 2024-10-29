#!/usr/bin/env bash


in_dir=$1
out_dir=$2
index_files=$3

# iterating through each FASTQ paired-end sample
for r1 in ${in_dir}/*R1.fastq.gz; do
        st=$(date '+%s')

        r2=$(echo $r1 | sed 's/R1.fastq.gz/R2.fastq.gz/')
        out_prefix=${out_dir}/$(basename $r1 | sed 's/_R1.fastq.gz//')

	echo "Aligning $(basename $out_prefix) to Reference, converting SAM to BAM format while filtering out all the unaligned reads, \
		sorting the BAMs, merging all the split BAMs into one, and saving it to ${out_prefix}.bam"

	# iterating through each split Index file
	for index in $(ls ${index_files}*.1.ht2 | sed 's/.1.ht2//'); do
		st_index=$(date '+%s')

		hisat2 \
			--summary-file ${out_prefix}_index${index:(-1)}_summary.txt \
			-p 8 \
			-x $index \
			-1 $r1 \
			-2 $r2 | samtools view -@ 8 -ShbF 4 - | samtools sort -O bam -o ${out_dir}/temp_${index:(-1)}.bam -

		et_index=$(date '+%s')
		echo Time for each index - $((et_index - st_index)) seconds

	done

	# merging all the temp bams
	samtools merge -o ${out_prefix}.bam -@ 8 ${out_dir}/temp*bam 
	rm ${out_dir}/temp*bam

        et=$(date '+%s')
        echo "FASTQ:$(realpath $out_prefix);Time Elapsed:$((et - st)) seconds" >> ${out_dir}/hisat2_alignment_run_time.log
done
