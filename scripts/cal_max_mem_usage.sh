#!/usr/bin/env bash

in_file=$1

value=$(grep "Mem" $in_file | sed 's/ \+/ /g' | cut -d" " -f3 | sort -k1,1h | tail -n 1)
echo $(realpath $in_file) $value
