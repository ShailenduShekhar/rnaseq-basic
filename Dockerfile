FROM ubuntu:24.04 AS base_image

LABEL image.author.name "Shailendu Shekhar Mohapatra"
LABEL image.author.email "shailendumohapatra@gmail.com"

RUN apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y \
	python3.12 \
	python3.12-venv \
	python3-pip \
	default-jre \
	default-jdk \
	wget \
	curl \
	unzip \
	libncurses5-dev \
	libbz2-dev \
	liblzma-dev \
	&& /usr/bin/python3.12 -m venv /py-mod \
	&& ln -s /py-mod/bin/python3.12 /usr/bin/python \
	&& . /py-mod/bin/activate \
	&& pip install numpy==2.0.2 \
		pandas==2.2.3 \
		pydeseq2==0.4.12 \
		matplotlib==3.9.2 \
		seaborn==0.13.2 \
		biopython==1.84 \
		multiqc==1.25.1 \
	&& wget https://github.com/samtools/samtools/releases/download/1.21/samtools-1.21.tar.bz2 \
	&& tar -xf samtools-1.21.tar.bz2 \
	&& cd samtools-1.21 \
	&& mkdir -p /apps/samtools-1.21 \
	&& ./configure --prefix=/apps/samtools-1.21 \
	&& make \
	&& make install \
	&& rm -rf /samtools-1.21*

RUN curl -L -o hisat2-2.2.1.zip https://cloud.biohpc.swmed.edu/index.php/s/oTtGWbWjaxsQ2Ho/download \
	&& unzip hisat2-2.2.1.zip \
	&& mv hisat2-2.2.1 /apps/hisat2-2.2.1 \
	&& rm -rf hisat2-2.2.1.zip \
	&& wget http://opengene.org/fastp/fastp.0.23.4 \
	&& mv fastp.0.23.4 /apps/fastp \
	&& chmod a+x /apps/fastp \
	&& wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip \
	&& unzip fastqc_v0.12.1.zip \
	&& mv FastQC /apps/ \
	&& rm -rf fastqc_v0.12.1.zip \
	&& wget https://github.com/ShiLab-Bioinformatics/subread/releases/download/2.0.2/subread-2.0.2-Linux-x86_64.tar.gz \
	&& tar -xf subread-2.0.2-Linux-x86_64.tar.gz \
	&& mv subread-2.0.2-Linux-x86_64 /apps/ \
	&& rm subread-2.0.2-Linux-x86_64.tar.gz

COPY ./scripts/ /scripts/

ENV PATH=${PATH}:/py-mod/bin:/apps/:/apps/FastQC/:/apps/hisat2-2.2.1/:/apps/subread-2.0.2-Linux-x86_64/bin:/scripts/:/apps/samtools-1.21/bin
ENV PYTHONPATH=/py-mod/lib/python3.12/site-packages/
ENV TZ=TIMEZONE
