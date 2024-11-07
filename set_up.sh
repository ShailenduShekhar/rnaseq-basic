#!/usr/bin/bash

image="rnaseq-basic:1"

timedatectl show | head -n 1 | cut -d"=" -f2 > timezone.txt
tz=$(cat timezone.txt)
echo Time Zone found - $tz
sed -i "s|TIMEZONE|$tz|" Dockerfile
rm timezone.txt

docker build -t "$image" .

[[ $? -eq 0 ]] && echo "Docker image $image is ready" || echo "Docker build failed"
