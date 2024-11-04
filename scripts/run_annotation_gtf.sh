#!/usr/bin/bash

# defining colors
highlight=$(get_color.py pink)
nc=$(get_color.py nc)
green=$(get_color.py green)
red=$(get_color.py red)

print_log() {
        echo -e [$(date '+%D %H:%M:%S')] [${highlight}annotation-gtf${nc}] $1 | tee -a "$logfile"
}

gtf=$1
ss=$2
exon=$3
logfile=$4

print_log "Extracting the splice sites and exons from the GTF file ..."

st=$(date '+%s')

	hisat2_extract_splice_sites.py "$gtf" > "$ss" & ss_pid=$!

	hisat2_extract_exons.py "$gtf" > "$exon" & exon_pid=$!

wait "$ss_pid"
ss_exit_code=$?
wait "$exon_pid"
exon_exit_code=$?

et=$(date '+%s')

if [[ "$exon_exit_code" -eq 0 && "$ss_exit_code" -eq 0 ]]; then
	print_log "Split sites and exons extraction ${green}successful${nc}. Runtime: $((et - st)) s"
else
	print_log "Split sites and exons extraction ${red}unsuccessful${nc}. Runtime: $((et - st)) s"
fi
