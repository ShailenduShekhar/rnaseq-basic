#!/usr/bin/bash


# options that cannot be changed by the user
logfile=$(pwd)/rnaseq_basic.log
cpu=$(nproc)
ram_factor=54

# setting the color options
red="\033[0;31m"
blue="\033[01;34m"
bror="\033[0;33m"
nc="\033[0m"

help () {
	echo """
USAGE:

(*): Required Argument

	-i    : Input directory containing FASTQ files in the format - *R1/2.fastq.gz
	-o (*): Output directory which would contain all the outputs produced by the analysis pipeline
	-r    : Reference FASTA sequence (*.fa or *.fasta)
	-a    : Enable building the reference index using the exon and split sites annotated information (default: disabled)
	-g    : GTF file
	-f    : Enable FASTP (default: disabled)
		If enabled, FASTP would run with the default parameters. 
	""" >&2
}

print_log() {
	echo -e [$(date '+%D %H:%M:%S')] $1 | tee -a $logfile
}

check_dir_exists() {
	if [[ ! -d $1 ]]; then
		print_log "${bror}Directory${nc} ${red}$1${nc} does not exist.\n Terminating the pipeline."
		exit 1
	fi
}

check_file_exists() {
	if [[ ! -f $1 ]]; then
		print_log "${bror}File${nc} ${red}$1${nc} does not exist.\n Terminating the pipeline."
		exit 1
	fi
}

check_null_value() {
	if [[ -z $1 ]]; then
		print_log "A ${red}required argument${nc} found empty.\nCheck help with '-h'."
		exit 1
	fi
}

if [[ $# -eq 0 ]]; then
	print_log "No arguments detected. \n Terminating the pipeline."
	help
	exit
fi

# setting the default options
f=false
a=false

while getopts "hi:o:fr:g:" option; do
	case $option in
		i)
		in_dir=$(realpath $OPTARG)
		check_dir_exists $in_dir
		;;

		o)
		out_dir=$(realpath $OPTARG)
		;;

		f)
		f=true
		;;

		r)
		ref=$(realpath $OPTARG)
		check_file_exists $ref
		;;

		a)
		a=true
		;;

		g)
		gtf=$(realpath $OPTARG)
		;;

		h) help
		exit 0;;

		*) 
		echo Invalid Option!
		help
		exit 1;;
	esac
done

# checking arguments
check_null_value $out_dir

print_log "Input directory : $in_dir"
print_log "Output directory : $out_dir"

if [[ $f == true ]]; then
	print_log "FASTP enabled"
else
	print_log "FASTP disabled"
fi

<<com

# running FASTQC
fastqc_res=${out_dir}/fastqc_results
mkdir -p $fastqc_res
print_log "Running FASTQC on $cpu threads ..."
st=$(date '+%s')

docker run --rm -v ${in_dir}:${in_dir} -v ${out_dir}:${out_dir} \
	rnaseq-basic:1 fastqc -o $fastqc_res \
		-t $cpu ${in_dir}/*R?.fastq.gz > $fastqc_res/fastqc_stdout.txt 2>&1

et=$(date '+%s')
print_log "FASTQC successful. Runtime: $((et - st)) s"

# running MultiQC
multiqc_res=${out_dir}/multiqc_results
mkdir -p $multiqc_res
print_log "Running MultiQC ..."
st=$(date '+%s')

docker run --rm -v ${out_dir}:${out_dir} \
	rnaseq-basic:1 multiqc -o $multiqc_res ${fastqc_res} > ${multiqc_res}/multiqc_stdout.txt 2>&1

et=$(date '+%s')
print_log "MultiQC successful. Runtime: $((et - st)) s"

# Splitting the reference sequence, if needed
print_log "Preparing for HISAT2 index building ..."

ram=$(free -m | grep "Mem" | sed 's/ \+/\t/g' | cut -f 2)
split_fa_size=$(($ram / $ram_factor))
ref_size=$(($(du -b $ref | cut -f1) / (1024 * 1024)))

if [[ $split_fa_size -gt $ref_size ]]; then
	print_log "Reference file splitting is NOT needed. Directly proceeding to HISAT2 index building ..."
	#HISAT2 build command here
else
	print_log "Reference file splitting is needed."

	split_out=${out_dir}/split_ref_fasta
	mkdir -p $split_out

	print_log "Available System RAM: $ram"
	print_log "Size of Split FASTA Reference: $split_fa_size"
	print_log "Splitting the FASTA Reference sequence ..."

	ref_input_dir=$(realpath $(dirname $ref))
	st=$(date '+%s')
	docker run --rm -v $ref_input_dir:$ref_input_dir -v $out_dir:$out_dir \
		rnaseq-basic:1 split_fasta_sequence.py $ref $split_fa_size $split_out \
		> $split_out/split_fasta_sequence_stdout.txt 2>&1

	split_fa_exit_code=$?

	et=$(date '+%s')

	if [[ $split_fa_exit_code -eq 0 ]]; then
		print_log "Splitting FASTA file successful. Runtime: $((et - st)) s"
	else 
		print_log "Splitting FASTA file unsuccessful.\n Terminating the pipeline."
		exit 1
	fi

	# generating the split sites and exons from the gtf file
	print_log "Extracting the split sites and exons from the GTF file ..."

	gtf_input_dir=$(realpath $(dirname $gtf))
	ss=${split_out}/hisat2_splice_sites.txt
	exon=${split_out}/hisat2_exons.txt
	
	st=$(date '+%s')

	docker run --rm -v $gtf_input_dir:$gtf_input_dir -v $out_dir:$out_dir \
		rnaseq-basic:1 hisat2_extract_splice_sites.py $gtf > $ss & ss_pid=$!

	docker run --rm -v $gtf_input_dir:$gtf_input_dir -v $out_dir:$out_dir\
		rnaseq-basic:1 hisat2_extract_exons.py $gtf > $exon & exon_pid=$!

	wait $ss_pid
	ss_exit_code=$?
	wait $exon_pid
	exon_exit_code=$?

	et=$(date '+%s')

	if [[ $exon_exit_code -eq 0 && $ss_exit_code -eq 0 ]]; then
		print_log "Split sites and exons SUCCESSFULLY extracted. Runtime: $((et - st)) s"
	else
		print_log "Split sites and exons extraction UNSUCCESSFULL. Runtime: $((et - st)) s"
	fi
	
	# running HISAT2-build for all the split reference sequence, if needed
	hisat2_index_dir=${out_dir}/hisat2_split_ref_index
	mkdir -p $hisat2_index_dir

	st=$(date '+%s')

	docker run --rm -v $out_dir:$out_dir rnaseq-basic:1 \
		run_hisat2_build.sh $split_out $hisat2_index_dir $ss $exon $logfile

	hisat2_index_exit_code=$?
	et=$(date '+%s')

	if [[ $hisat2_index_exit_code -eq 0 ]]; then
		print_log "HISAT2 Index building SUCCESSFULL. Runtime: $((et - st)) s"
	else
		print_log "HISAT2 Index building UNSUCCESSFULL. Runtime: $((et - st)) s"
	fi
com
	# hisat2 alignment, SAM to BAM conversion, filtering out unaligned reads, sorting BAM files, and merging BAM files of the same sample
	hisat2_bam_dir=${out_dir}/hisat2_alignment_bams
	mkdir -p $hisat2_bam_dir

	# temp variables
	hisat2_index_dir=/mnt/e/company_selection/biostate_ai/rnaseq-basic/trial_output/hisat2_split_ref_index

	docker run --rm -v $in_dir:$in_dir -v $out_dir:$out_dir rnaseq-basic:1 \
		run_hisat2_alignment.sh $in_dir $hisat2_bam_dir $hisat2_index_dir $logfile
#fi
