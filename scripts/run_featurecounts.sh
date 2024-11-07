#!/usr/bin/env bash


input_dir=$1
outdir=$2
anot_file=$3
cpu=$4

featureCounts \
	-p --countReadPairs \
	-T "$cpu" \
	-a "$anot_file" \
	-o "$outdir"/all_bam_quant.txt \
	$(ls ${input_dir}/*bam | xargs) > "$outdir"/featureCounts_stdout.txt 2>&1
