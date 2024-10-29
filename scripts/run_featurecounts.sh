#!/usr/bin/env bash


input_dir=$1
outfile=$2
anot_file=$3

echo Using featureCounts to quantify the BAM files ...

st=$(date '+%s')

featureCounts \
	-p --countReadPairs \
	-T 8 \
	-a $anot_file \
	-o ${outfile} \
	$(ls ${input_dir}/*bam | xargs) > /dev/null 2>&1

et=$(date '+%s')

echo "BAM files processed:$(ls ${input_dir}/*bam | wc);Runtime:$((et - st))"
