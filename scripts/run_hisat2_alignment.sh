#!/usr/bin/bash


in_dir=$1
out_dir=$2
index_files=$3
logfile=$4

# defining the colors
highlight=$(docker run --rm rnaseq-basic:1 get_color.py pink)
nc=$(docker run --rm rnaseq-basic:1 get_color.py nc)

print_log() {
        echo -e [$(date '+%D %H:%M:%S')] [${highlight}hisat2_alignment${nc}] $1 | tee -a $logfile
}


# iterating through each FASTQ paired-end sample
for r1 in ${in_dir}/*R1.fastq.gz; do
        st=$(date '+%s')

        r2=$(echo $r1 | sed 's/R1.fastq.gz/R2.fastq.gz/')
        out_prefix=${out_dir}/$(basename $r1 | sed 's/_R1.fastq.gz//')

	print_log "Processing sample $(basename $out_prefix) ..."

	# iterating through each split Index file
	for index in $(ls ${index_files}/*.1.ht2 | sed 's/.1.ht2//'); do
		hisat2 \
			--summary-file ${out_prefix}_index${index:(-1)}_summary.txt \
			-p 8 \
			-x $index \
			-1 $r1 \
			-2 $r2 2>/dev/null \
			| samtools view -@ 8 -ShbF 4 - 2>/dev/null \
			| samtools sort -O bam -o ${out_dir}/temp_${index:(-1)}.bam - 2>/dev/null
	done

	# merging all the temp bams
	samtools merge -o ${out_prefix}.bam -@ 8 ${out_dir}/temp*bam 2>/dev/null
	rm ${out_dir}/temp*bam

        et=$(date '+%s')
        print_log "BAM file ready for sample $(basename $out_prefix). Runtime: $((et - st)) s"
done
