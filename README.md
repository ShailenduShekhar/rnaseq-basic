# rnaseq-basic
## Introduction
This tool uses a docker image that contains all the software and custom scripts needed for a basic RNASeq analysis.
Currently, it is designed towards low resource environments so as to facilitate tools which demand very high primary memory to operate, such as HISAT2-build. This tool was tested in a WSL2 environment, with 24 GB RAM and 16 processing units.
## Prerequisites and Installation
An Ubuntu OS and docker is all that is needed to set up this pipeline.
To install the tool, you simply have to clone the GitHub repository and build the docker image using the following commands.
```
1. git clone git@github.com:ShailenduShekhar/rnaseq-basic.git
2. cd rnaseq-basic
3. ./set_up.sh
```
The rnaseq-basic:1 pipeline is now ready to use. The following command would print the “help” options to the STDOUT.
```
1. ./rnaseq_basic_1.sh -h
```
## Tool Overview
This pipeline incorporates the following steps of a classic RNASeq analysis:
1.	QC Check
- Includes both FASTQC and MultiQC.
- Providing the ‘-q’ option would enable this step.
2. Adapter Trimming
- Uses Fastp to trim the input FASTQ files.
- Only supports paired-end reads, as of this version.
- Providing the ‘-f’ option would enable this step.
3. HISAT2 Index building
- Internally uses hisat2-build command to create an index.
-	Reference can be provided through the ‘-r’ option.
-	Splice sites and exon information can be included by providing the ‘-a’ option, and not providing the same would instruct the pipeline to build the index without annotations.
-	GTF file can be provided through the ‘-g’ option.
4. HISAT2 Index
-	If index is already available, then the path to that directory can be provided with the ‘-x’ option.
-	Note that this directory should only contain the index of interest.
-	If more than one index is present then the resultant BAM file would be a merge of all the BAMs from the respective indexes. More on this below in the “HISAT2 Index Building and its complexities” section.
-	Also note that the options ‘-r’ and ‘-a’ are mutually exclusive to option ‘-x’.
5. HISAT2 Alignment
-	Internally uses hisat2 in order to align FASTQ files to the preferred choice of HISAT2 index.
 -	If Fastp was enabled, then the input FASTQ files for this step would be the output of that tool.
-	The unaligned reads are filtered out from the resulting SAM file, converted to BAM format, sorted and merged.
6. Quantification
-	Internally uses featureCounts tool that takes each of the BAM files produced above.
-	This step produces a TSV file that contains the read count data for all the samples.
## HISAT2 Index Building and its complexities
A human genome (approximately 3 GB in size) would require [160 GBs of RAM to build HISAT2 index](https://github.com/griffithlab/rnaseq_tutorial/wiki/Indexing#:~:text=WARNING%3A%20In%20order%20to%20index%20the%20entire%20human%20genome%2C%20HISAT2%20requires%20160GB%20of%20RAM.). To get around this problem, the reference FASTA file had to be split into parts, where each part would ideally be within a given size limit. This size limit can be calculated by the available system RAM and a constant factor.
**rnaseq-basic:1** pipeline automatically calculates and splits the provided reference file following which hisat2-build is executed on each of the parts. During the alignment step, each FASTQ file is aligned to each of the split-indexes separately, and the resultant BAM files are merged into one.
