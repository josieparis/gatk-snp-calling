# gatk-snp-calling
Full GATK SNP calling pipeline

This set of scripts take raw illumina whole-genome sequencing reads as input to produce a filtered VCF file

These scripts were written for a PBS batch cluster system

We provide a short bash script to convert PBS headers to SLURM (`liftover_PBS2SLURM.sh`) (but please check these before starting)

Conversion to SGE should be relatively straightforward (we will add another liftover script for this in the future ...)

#### These scripts have been used to create VCF files in the following publications:

Fraser BA, Whiting JR, Paris JR, Weadick CJ, Parsons PJ, Charlesworth D, Bergero R, Bemm F, Hoffmann M, Kottler VA, Liu C, Dreyer C, Weigel D (2020). Improved reference genome uncovers novel sex-linked regions in the guppy (Poecilia reticulata). Genome Biology and Evolution, evaa187. https://doi.org/10.1093/gbe/evaa187

Whiting JR, Paris JR, van der Zee MJ, Parsons, PJ, Weigel D, Fraser BA. Drainage-structuring of ancestral variation and a common functional pathway shape limited genomic convergence in natural high- and low-predation guppies. bioRxiv: https://doi.org/10.1101/2020.10.14.339333


### For these scripts to work, you need to set up a neat waterfall workspace

![directory_structure 001](https://user-images.githubusercontent.com/38511308/105726962-7f0cbc80-5f22-11eb-85b3-f7854e1c27b9.jpeg)


This directory structure is provided for you on the git clone, or else you can make it quickly yourself:

`mkdir SNP_calling && cd SNP_calling && mkdir scripts reads bams gvcfs vcfs && cd scripts && mkdir logs && cd .. && cd reads && mkdir raw_reads clean_reads && cd raw_reads && mkdir fastqc && cd ../clean_reads && mkdir fastqc && cd ../../ && cd bams && mkdir raw_bams interim_bams clean_bams && cd ../vcfs/ && mkdir interim_vcfs && mkdir intervals && cd ..`

#### Here's a list of the scripts and a brief description of what they do:

## 1_qc_clean.sh
Takes raw illumina reads and runs fastqc, cleans the reads using trim_galore, performs fastqc on the clean reads

## 2_bwa_align.sh
Aligns clean reads to a reference genome to form sam, converts to bam, sort, index, flagstat (for mapping stats). Includes a quick sanity check at the end to make sure the sorted.raw.bam files are in good shape

## 3_add_readgroups.sh
Adds readgroup information from a metadata file, where columns specify which read group info should be added

## 4_dedup.sh
##### NB Technically this first run of marking duplicates is not necessary because we will run it again per-sample, and that per-sample marking would be enough to achieve the desired result.  We only do this round of marking duplicates for QC purposes                                                              
Marks duplicates in the bam files

## 5_merge_sample_bams.sh
Merges bams from data generated from one sample which is in multiple fastq files
##### NB This merging only needs to happen if you have multiple fastq files for one sample, i.e. one individual sample which has been run across multiple lanes, e.g. sample_1A.fastq sample_1B.fastq. If you have one set of reads per sample you can skip this script (and the next one too)   

## 6_dedup.sh                                         
Marks duplicates in bams from multiple lanes of sequencing

## 7_recal.sh   
Recalibrates the bam files against a "truth-set" of SNPs

##### Truth-set vcfs are variants for which we have high confidence, and tend to be generated from PCR-free high coverage libraries. If you don't have one of these available, skip this step. In such cases I reccommend calling variants with GATK, and then also calling variants with another program (e.g. Freebayes). When the VCFs of each caller are complete you can intersect them using `bedtools intersect` and keep the SNPs which were called by both programs. IF variants have been called in both programs, this offers you some confidence.

## 8_haplotype_caller.sh
This script runs GATK's haplotype caller on your bams, and produces gvcf files for GATK4 CombineGVCFs
### NB This script takes the longest time to run

## 9_consolidate_genotypes.sh
Runs GATK4 GenomicsDBImport and GenotypeGVCFs

## 10_refine_filter.sh
Uses GATK4 SelectVariants, vcftools for various filters (user can choose!) and finally GATK3 CombineVariants to merge samples generated from multiple populations

### To run the scripts:
- Check which batch submission system your cluster is running, i.e. SGE, PBS, SLURM

### Important Metadata 
The reliability of these scripts relies heavily on a metadata file, which you will have to create prior to running the pipeline.
The metadata file can have any information you require in it, e.g. sampling location, sex, sample ID etc etc. In fact, it's good habit to have a metadata file such as this associated with any sequencing project. Below I provide an example of a metadata file structure. It's a tsv file, with columns and rows. Can easily be made in Excel and saved as a .tsv ;)


| simple_ID | sample_ID | read1 | read2 | instrument | flowcell | lane | barcode | sex | run_num | seq_num |
| ---------- | ----------  | ----------  | ---------- | ---------- | ---------- | ----------  | ---------- | ---------- | ---------- | ---------- |
| APLP_F1 | APLP_F1_A_L001 | APLP_F1_A_L001_r1.fq.gz | APLP_F1_A_L001_r2.fq.gz | ILLUMINA | A | 1 | ATGCA | F | 44 | 1 |
| APLP_F1 | APLP_F1_A_L002 | APLP_F1_A_L002_r1.fq.gz | APLP_F1_A_L002_r2.fq.gz | ILLUMINA | A | 2 | ATGCA | F | 44 | 1 |
| APLP_F1 | APLP_F1_A_L003 | APLP_F1_A_L003_r1.fq.gz | APLP_F1_A_L003_r2.fq.gz | ILLUMINA | A | 3 | ATGCA | F | 41 | 1 |
| APLP_F2 | APLP_F2_A_L001 | APLP_F2_A_L001_r1.fq.gz | APLP_F2_A_L001_r2.fq.gz | ILLUMINA | A | 1 | GTCTA | F | 44 | 1 |
| APLP_F2 | APLP_F2_A_L002 | APLP_F2_A_L002_r1.fq.gz | APLP_F2_A_L002_r2.fq.gz | ILLUMINA | A | 2 | GTCTA | F | 44 | 1 |
| APLP_F2 | APLP_F2_A_L003 | APLP_F2_A_L003_r1.fq.gz | APLP_F2_A_L003_r2.fq.gz | ILLUMINA | A | 3 | CTAGA | F | 41 | 1 |
| APLP_M1 | APLP_M1_A_L001 | APLP_M1_A_L001_r1.fq.gz | APLP_M1_A_L001_r2.fq.gz | ILLUMINA | A | 1 | CAAGC | M | 44 | 1 |
| APLP_M1 | APLP_M1_B_L001 | APLP_M1_B_L001_r1.fq.gz | APLP_M1_B_L001_r2.fq.gz | ILLUMINA | B | 1 | CAAGC | M | 44 | 1 |
| APLP_M1 | APLP_M1_C_L001 | APLP_M1_C_L001_r1.fq.gz | APLP_M1_C_L001_r2.fq.gz | ILLUMINA | C | 1 | CAAGC | M | 44 | 1 |



```
simple_ID 	sample_ID 	  read1 read2 instrument 	flow_cell	lane 	barcode	sex	run_num seq_num
APLP_F1		APLP_F1_A_L001	  ILLUMINA 	A		1	ATGCA	F	44  1
APLP_F1		APLP_F1_A_L002	  ILLUMINA 	A		2	ATGCA	F	44  1
APLP_F1		APLP_F1_A_L003	  ILLUMINA 	A		3	ATGCA	F	41  1
APLP_F2		APLP_F2_A_L001	  ILLUMINA 	A		1	GTCTA	F	44  1
APLP_F2		APLP_F2_A_L002	  ILLUMINA 	A		2	GTCTA	F	44  1
APLP_F2		APLP_F2_A_L003	  ILLUMINA 	A		3	CTAGA	F	41  1
APLP_M1		APLP_M1_A_L001	  ILLUMINA 	A		1	CAAGC	M	44  1
APLP_M1		APLP_M1_B_L001	  ILLUMINA 	B		1	CAAGC	M	44  1
APLP_M1		APLP_M1_C_L001	  ILLUMINA 	C		1	CAAGC	M	41  1
```

#### Info on this metadata
simple_ID = name of individual

sample_ID = name of read pertaining to that individual

instrument = One of ILLUMINA, SOLID, LS454, HELICOS and PACBIO (must be in caps!)

flow_cell = flowcell ID that the sample was run on

lane = lane the sample was run on

run_num = run number of the fastq reads

seq_num = library prep number. Sometimes you have an index for this. We only did one library per sample, hence all are 1. 

In this example metadata, we have several fastq files for each sample
For example, sample `APLP_F1` is comprised of three sets of fastq reads: `APLP_F1_A_L001`, `APLP_F1_A_L002`, `APLP_F1_A_L003` and we can see in the metadata that they come from three different lanes of sequencing (1,2,3) on flow_cell A. 
On the other hand, `APLP_F2` are also derived from the same flow_cell (A), across three lanes (1,2,3), but one of the samples has a different barcode
Finally, `APLP_M1` is sequenced on lane 1, but across three different flow cells (A, B, C). 
This example is just for illustrative purposes so you can see the differences between the metdata columns. 

#### Where do I get the metadata?
Much of these metdata can be collected from your fastq read headers:
@(instrument id):(run number):(flowcell ID):(lane):(tile):(x_pos):(y_pos) (read):(is filtered):(control number):(index sequence)FLOWCELL_BARCODE = @(instrument id):(run number):(flowcell ID)

#### Depending on how you edit and put together your metadata, you will have to check each script to make sure it pulls out the correct column of data.
For example, 

In `1_qc_clean.sh`, we take the second column which is the name of the fastq reads

```
read1=( `cat $metadata | cut -f 2` )
read1_array=$raw_reads/${read1[(($MOAB_JOBARRAYINDEX))]}

read2=( `cat $metadata | cut -f 2` )
read2_array=$raw_reads/${read2[(($MOAB_JOBARRAYINDEX))]}
```

and we append \_R1.fastq and \_R2.fastq to the end of the file name in the script:

```
trim_galore -q 20 --path_to_cutadapt cutadapt -o $clean_reads --phred33 --paired ${read1_array}_R1.fastq.gz ${read2_array}_R2.fastq.gz
```

In `3_add_readgroups.sh` we also use a lot of this information too ...

### Read Groups

#### RGSM
(sample name) = simple_ID
#### RGLB
(DNA preparation library identifier) = simple_ID.seq_num (or index identifed from your library prep)
##### NB This is important to identify PCR duplicates in MarkDuplicates step. You can ignore this readgroup for PCR-free libraries
#### RGID
(Read group identifier) = flow_cell.lane
#### RGPU
(Platform Unit) = flow_cell.lane.barcode
#### RGPL
(Platform) = instrument
##### NB takes one of ILLUMINA, SOLID, LS454, HELICOS and PACBIO - must be in caps!

You can get a lot of this read group information from your fastq files.

@(instrument id):(run_num):(flow_cell):(lane):(tile):(x_pos):(y_pos) (read):(filtered):(control_num):(index sequence)

#### NB This should be used as a guide only. Read group assignment changes depending on your library preparation set-up and type of sequencing data


## At the end of the process, we highly reccommend running MultiQC on your directories to collect data on quality control:
https://multiqc.info/ 

##### With thanks to Bonnie Fraser, Mijke van der Zee and Jim Whiting



