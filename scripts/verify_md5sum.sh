#!/usr/bin/bash

md5_dir=$1
fastq_dir=$2

echo Checking md5 values for each file in $(realpath $fastq_dir)

for file in $md5_dir/*md5; do
	while read -r check filename; do 
		check_value=$(md5sum $fastq_dir/$filename | awk '{print $1}')
		if [[ $check == $check_value ]]; then 
			echo $filename Equal
		else 
			echo $filename Not Equal
		fi
	done<$file
done
