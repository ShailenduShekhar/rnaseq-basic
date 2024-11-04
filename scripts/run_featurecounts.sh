#!/usr/bin/env bash


input_dir=$1
outdir=$2
anot_file=$3
cpu=$4

# defining the colors
highlight=$(get_color.py pink)
nc=$(get_color.py nc)

print_log() {
        echo -e [$(date '+%D %H:%M:%S')] [${highlight}featureCounts${nc}] $1 | tee -a $logfile
}

print_log "Using featureCounts to quantify the BAM files ..."

featureCounts \
	-p --countReadPairs \
	-T "$cpu" \
	-a "$anot_file" \
	-o "$outdir"/all_bam_quant.txt \
	$(ls ${input_dir}/*bam | xargs) > "$outdir"/featureCounts_stdout.txt 2>&1
