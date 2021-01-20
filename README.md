# gatk-snp-calling
Full GATK SNP calling pipeline

This set of scripts take raw illumina whole-genome sequencing reads as input to produce a filtered VCF file

These scripts were written for a PBS batch cluster system and have since been rewritten for a SLURM batch system. I also have older ones available for SGE, which I can send by request (they may need some updating)

#### These scripts have been used to create VCF files in the following publications:

Fraser BA, Whiting JR, Paris JR, Weadick CJ, Parsons PJ, Charlesworth D, Bergero R, Bemm F, Hoffmann M, Kottler VA, Liu C, Dreyer C, Weigel D (2020). Improved reference genome uncovers novel sex-linked regions in the guppy (Poecilia reticulata). Genome Biology and Evolution, evaa187. https://doi.org/10.1093/gbe/evaa187

Whiting JR, Paris JR, van der Zee MJ, Parsons, PJ, Weigel D, Fraser BA. Drainage-structuring of ancestral variation and a common functional pathway shape limited genomic convergence in natural high- and low-predation guppies. bioRxiv: https://doi.org/10.1101/2020.10.14.339333

And more to follow! 


### For these scripts to work, you need to set up a neat waterfall workspace

![directory_structure](https://user-images.githubusercontent.com/38511308/105203421-ff09df80-5b3a-11eb-92b5-33389dbc7a1f.jpeg)


`mkdir SNP_calling && cd SNP_calling && mkdir scripts reads bams gvcfs vcfs && cd scripts && mkdir logs && cd .. && cd reads && mkdir raw_reads clean_reads && cd raw_reads && mkdir fastqc && cd ../clean_reads && mkdir fastqc && cd ../../ && cd bams && mkdir raw_bams interim_bams clean_bams && cd ../`

### Once the directory structure is set up, we can get started.

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
##### NB This merging only needs to happen if you have multiple fastq files for one sample, i.e. one individual sample which has been run across multiple lanes, e.g. sample_1A.fastq sample_1B.fastq. If you have one set of reads per sample you can skip this script (and the next one too)                                    
Merges bams from multiple lanes of sequencing

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

### Important Metadata 
The reliability of these scripts relies heavily on a metadata file, which you will have to create prior to running the pipeline.
The metadata file can have any information you require in it, e.g. sampling location, sex, sample ID etc etc. In fact, it's good habit to have a metadata file such as this associated with any sequencing project. Below I provide an example of a metadata file structure. It's a tsv file, with columns and rows. Can easily be made in Excel and saved as a .tsv ;)

```
simple_ID 	sample_ID 		  instrument 	flow_cell	lane 	barcode	sex	seq_num	run_num
APLP_F1		  APLP_F1_A_L001	ILLUMINA 	    A			  1		  ATGCA	   F	1 		44 
APLP_F1		  APLP_F1_A_L002	ILLUMINA 	    A			  2		  ATGCA	   F	1 		44 
APLP_F1		  APLP_F1_A_L003	ILLUMINA 	    A			  3		  ATGCA    F	1 		41 
APLP_F2		  APLP_F2_A_L001	ILLUMINA 	    A			  1		  GTCTA	   F	1 		44 
APLP_F2		  APLP_F2_A_L002	ILLUMINA 	    A			  2		  GTCTA	   F	1 		44 
APLP_F2		  APLP_F2_A_L003	ILLUMINA 	    A			  3		  CTAGA	   F	1 		41 
APLP_M1		  APLP_M1_A_L001	ILLUMINA 	    A			  1		  CAAGC	   M	1 		44 
APLP_M1		  APLP_M1_B_L001	ILLUMINA 	    B			  1		  CAAGC	   M	1 		44 
APLP_M1		  APLP_M1_C_L001	ILLUMINA 	    C			  1		  CAAGC	   M	1 		41 
```







##### With thanks to Bonnie Fraser, Mijke van der Zee and Jim Whiting



