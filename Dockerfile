FROM ubuntu:24.04 AS base_image

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y python3.12 \
	python3.12-venv \
	python3-pip \
	default-jre \
	default-jdk \
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
ENV PYTHONPATH=/py-mod/lib/python3.12/site-packages/
