#!/usr/bin/bash


# options that cannot be changed at execution time
cpu=$(nproc)
ram_factor=54

# defining the colors
red=$(docker run --rm rnaseq-basic:1 get_color.py red)
blue=$(docker run --rm rnaseq-basic:1 get_color.py blue)
green=$(docker run --rm rnaseq-basic:1 get_color.py green)
bror=$(docker run --rm rnaseq-basic:1 get_color.py brown-orange)
pink=$(docker run --rm rnaseq-basic:1 get_color.py pink)
nc=$(docker run --rm rnaseq-basic:1 get_color.py nc)


get_color() {
	echo $(docker run --rm rnaseq-basic:1 get_color.py $1)
}

help() {
	echo """
USAGE:

(*): Required Argument

	-i (*): Input directory containing FASTQ files in the format - *R1/2.fastq.gz
	-o (*): Output directory which would contain all the outputs produced by the analysis pipeline
	-q    : Disables FASTQC and MultiQC (default: enabled)
	-r (*): Reference FASTA sequence (*.fa or *.fasta)
	-g    : GTF file (If provided, enables annotation of the HISAT2 index building by default)
	-f    : Enables FASTP (default: disabled)
	-l (*): Log file
	"""
}

print_log() {
	echo -e [$(date '+%D %H:%M:%S')] "$1" | tee -a $logfile
}

print_error() {
	echo -e [$(date '+%D %H:%M:%S')] "$1"
}

check_dir_exists() {
	if [[ ! -d $1 ]]; then
		print_error "${bror}Directory${nc} ${red}"$1"${nc} does not exist. Terminating the pipeline."
		exit 1
	fi
}

check_null_dir_exists() {
	if [[ -z $1 ]]; then
                print_error "A required parameter ${red}"$2"${nc} found empty.Check help with '-h'."
                exit 1
        fi
	if [[ ! -d $1 ]]; then
                print_error "${bror}Directory${nc} ${red}"$1"${nc} does not exist. Terminating the pipeline."
                exit 1
        fi
	print_log "${blue}${3}${nc}  : ${1}"
}

check_null_file_exists() {
	if [[ -z $1 ]]; then
                print_error "A required parameter ${red}"$2"${nc} found empty.Check help with '-h'."
                exit 1
        fi
	if [[ ! -f $1 ]]; then
                print_error "${bror}File${nc} ${red}"$1"${nc} does not exist. Terminating the pipeline."
                exit 1
        fi
	print_log "${blue}${3}${nc} : ${1}"
}

check_file_exists() {
	if [[ ! -f $1 ]]; then
		print_error "${bror}File${nc} ${red}"$1"${nc} does not exist. Terminating the pipeline."
		exit 1
	fi
}

check_null_value() {
	if [[ -z $1 ]]; then
		print_error "A required parameter ${red}"$2"${nc} found empty.Check help with '-h'."
		exit 1
	fi
	print_log "${blue}${3}${nc} : ${1}"
}

run_qc() {
	# running FASTQC
	fastqc_res=${out_dir}/fastqc_results
	mkdir -p $fastqc_res
	print_log "Running FASTQC on $cpu threads ..."
	st=$(date '+%s')

	docker run --rm -v ${in_dir}:${in_dir} -v ${out_dir}:${out_dir} \
		rnaseq-basic:1 fastqc -o $fastqc_res \
			-t $cpu ${in_dir}/*R?.fastq.gz > $fastqc_res/fastqc_stdout.txt 2>&1

	fastqc_ec=$?
	et=$(date '+%s')
	[[ $fastqc_ec -eq 0 ]] && print_log "FASTQC ${green}successful${nc}. Runtime: $((et - st)) s" \
		|| print_log "FASTQC ${red}unsuccessful${nc}. Check ${fastqc_res}/fastqc_stdout.txt."

	# running MultiQC
	multiqc_res=${out_dir}/multiqc_results
	mkdir -p $multiqc_res
	print_log "Running MultiQC ..."
	st=$(date '+%s')

	docker run --rm -v ${out_dir}:${out_dir} \
		rnaseq-basic:1 multiqc -o $multiqc_res ${fastqc_res} > ${multiqc_res}/multiqc_stdout.txt 2>&1
	
	multiqc_ec=$?
	et=$(date '+%s')
	[[ $multiqc_ec -eq 0 ]] && print_log "MultiQC ${green}successful${nc}. Runtime: $((et - st)) s" \
		|| print_log "MultiQC ${red}unsuccessful${nc}. Check ${multiqc_res}/multiqc_stdout.txt."
}

splitfasta() {
	split_out=${out_dir}/split_ref_fasta
	mkdir -p $split_out

	print_log "[${pink}splitFASTA${nc}] Splitting the FASTA Reference sequence ..."

	ref_input_dir=$(realpath $(dirname $ref))
	st=$(date '+%s')
	docker run --rm -v $ref_input_dir:$ref_input_dir -v $out_dir:$out_dir \
		rnaseq-basic:1 split_fasta_sequence.py $ref $split_fa_size $split_out \
		> $split_out/split_fasta_sequence_stdout.txt 2>&1

	split_fa_exit_code=$?

	et=$(date '+%s')

	if [[ $split_fa_exit_code -eq 0 ]]; then
		print_log "[${pink}splitFASTA${nc}] Splitting FASTA file successful. Runtime: $((et - st)) s"
	else 
		print_log "[${pink}splitFASTA${nc}] SSlitting FASTA file unsuccessful.\n Terminating the pipeline."
		exit 1
	fi

	print_log "[${pink}splitFASTA${nc}] Original FASTA file was splitted into $(ls $split_out/*fa | wc -l) parts."
}


if [[ $# -eq 0 ]]; then
	echo -e "No arguments detected.\nTerminating the pipeline."
	help
	exit
fi

# setting the default options
q=true
f=false
annotation=false

while getopts "hi:o:fr:g:q" option; do
	case $option in
		i)
		in_dir=$(realpath $OPTARG)
		;;

		o)
		out_dir=$(realpath $OPTARG)
		;;

		q)
		q=false
		;;
		
		f)
		f=true
		;;

		r)
		ref=$(realpath $OPTARG)
		;;

		g)
		gtf=$(realpath $OPTARG)
		annotation=true
		;;

		l)
		logfile=$(realpath $OPTARG)
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
check_null_dir_exists "$in_dir" "-i" "Input Directory"
check_null_value "$out_dir" "-o" "Output Directory"
check_null_file_exists "$ref" "-r" "Reference"
check_null_value "$logfile" "-l" "Log file"

[[ "$annotation" == true ]] && {
	print_log "Annotation for HISAT2 index building ${green}enabled${nc}"
	check_null_file_exists "$gtf" "-g" "GTF"
} || print_log "Annotation for HISAT2 index building ${red}disabled${nc}"

[[ $q == true ]] && print_log "QC${green} enabled${nc}" || print_log "QC${red} disabled${nc}"

[[ $f == true ]] && print_log "FASTP${green} enabled${nc}" ||  print_log "FASTP${red} disabled${nc}"

# executing QC
[[ $q == true ]] && run_qc

# executing Fastp
[[ $f == true ]] && {
	print_log "Running FASTP ..."
	docker run --rm -v $in_dir:$in_dir -v $out_dir:$out_dir rnaseq-basic:1 \
		run_fastp.sh $in_dir $out_dir $cpu $logfile
}

# extracting exons and splice sites, if needed
[[ $annotation == true ]] && { 
	gtf_input_dir=$(realpath $(dirname $gtf))
	exon_ss_outdir=${out_dir}/annotation_files
	mkdir -p $exon_ss_outdir

	ss=${exon_ss_outdir}/hisat2_splice_sites.txt
	exon=${exon_ss_outdir}/hisat2_exons.txt

	docker run --rm -v "$gtf_input_dir":"$gtf_input_dir" -v "$exon_ss_outdir":"$exon_ss_outdir" \
		rnaseq-basic:1 run_annotation_gtf.sh "$gtf" "$ss" "$exon" "$logfile"
	annot_params="--ss ${ss} --exon ${exon}"
}

# Splitting the reference sequence, if needed
print_log "Preparing for HISAT2 index building ..."

ram=$(free -m | grep "Mem" | sed 's/ \+/\t/g' | cut -f 2)
split_fa_size=$(($ram / $ram_factor))
ref_size=$(($(du -b $ref | cut -f1) / (1024 * 1024)))


if [[ $split_fa_size -gt $ref_size ]]; then
	print_log "Reference file splitting is NOT needed. Directly proceeding to HISAT2 index building ..."

	ref_dir=$(realpath $(dirname $ref))
	hisat_index=${out_dir}/hisat2_index
	mkdir -p $hisat_index

	st=$(date '+%s')

	docker run --rm -v $ref_dir:$ref_dir -v $out_dir:$out_dir rnaseq-basic:1 \
		hisat2-build $annot_params \
                -p 1 \
                $ref \
		${hisat_index}/$(basename $ref) > ${hisat_index}/hisat2_build_stdout.txt 2>&1

        hisat_build_nosplit_ec=$?
        et=$(date '+%s')
	[[ $hisat_build_nosplit_ec -eq 0 ]] && {
		print_log "Reference Index is ready. Runtime: $((et - st))"
	} || print_log "Reference index building was unsuccessful"
else
	print_log "Reference file splitting is needed."
	print_log "Available System RAM: $ram MiB"
	print_log "Size of Split FASTA Reference: $split_fa_size MiB"
	splitfasta
	
	# running HISAT2-build for all the split reference sequence
	#print_log "[${pink}hisat2-build${nc}] Building HISAT2 index for Split FASTA ..."
	hisat2_index_dir=${out_dir}/hisat2_split_ref_index
	mkdir -p $hisat2_index_dir

	st=$(date '+%s')

	docker run --rm -v "$out_dir":"$out_dir" --cpus "$cpu" -m "23g" rnaseq-basic:1 \
		run_hisat2_build.sh "$split_out" "$hisat2_index_dir" "$annot_params" "$logfile"

	hisat2_index_exit_code=$?
	et=$(date '+%s')

	if [[ $hisat2_index_exit_code -eq 0 ]]; then
		print_log "[${pink}hisat2-index-build${nc}] HISAT2 Index building ${green}successful${nc}. Runtime: $((et - st)) s"
	else
		print_log "[${pink}hisat2-index-build${nc}] HISAT2 Index building ${red}unsuccessful${nc}. Runtime: $((et - st)) s"
	fi

	# hisat2 alignment, SAM to BAM conversion, filtering out unaligned reads, sorting BAM files, and merging BAM files of the same sample
	hisat2_bam_dir=${out_dir}/hisat2_alignment_bams
	mkdir -p $hisat2_bam_dir

	st=$(date '+%s')

	docker run --rm -v "$in_dir":"$in_dir" -v "$out_dir":"$out_dir" rnaseq-basic:1 \
		run_hisat2_alignment.sh "$in_dir" "$hisat2_bam_dir" "$hisat2_index_dir" "$cpu" "$logfile"

	et=$(date '+%s')
	hisat2_alignment_ec=$?

	if [[ "$hisat2_alignment_ec" -eq 0 ]]; then
		print_log "[${pink}hisat2-alignment${nc}] HISAT2 Alignment ${green}successful${nc}. Runtime: $((et - st)) s"
	else
		print_log "[${pink}hisat2-alignment${nc}] HISAT2 Alignment ${red}unsuccessful${nc}. Runtime: $((et - st)) s"
	fi

	# BAM file quantification using featureCounts tool
	quants=${out_dir}/quants_data
	mkdir -p "$quants"

	st=$(date '+%s')
	docker run --rm -v "$gtf_input_dir":"$gtf_input_dir" -v "$out_dir":"$out_dir" rnaseq-basic:1 \
		run_featurecounts.sh "$hisat2_bam_dir" "$quants" "$gtf" "$cpu"

	fc_ec=$?
	et=$(date '+%s')

	if [[ "$fc_ec" -eq 0 ]]; then
                print_log "[${pink}featureCounts${nc}] Quantification of BAM files ${green}successful${nc}. Runtime: $((et - st)) s"
        else
                print_log "[${pink}featureCounts${nc}] Quantification of BAM files ${red}unsuccessful${nc}. Runtime: $((et - st)) s"
        fi

fi
