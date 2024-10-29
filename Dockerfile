FROM ubuntu:24.04 AS base_image

RUN apt-get update \
	&& apt-get upgrade -yy \
	&& apt-get install python3.12 -yy \
	&& apt-get install python3.12-venv -yy \
	&& apt-get install python3-pip -yy \
	&& /usr/bin/python3.12 -m venv /py-mod \
	&& ln -s /py-mod/bin/python3.12 /usr/bin/python \
	&& . /py-mod/bin/activate \
	&& pip install numpy==2.0.2 \
		pandas==2.2.3 \
		pydeseq2==0.4.12 \
		matplotlib==3.9.2 \
		seaborn==0.13.2 \
		biopython==1.84 \
		multiqc==1.25.1

COPY ./tools/ /apps/
COPY ./scripts/ /scripts/

ENV PATH=${PATH}:/py-mod/bin:/apps/:/apps/FastQC/:/apps/hisat2-2.2.1/:/apps/subread-2.0.7-Linux-x86_64:/scripts/
