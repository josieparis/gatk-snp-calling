All scripts used for GATK pipeline:

1_qc_clean.sh
Takes raw illumina reads and runs fastqc, cleans the reads using trim_galore, performs fastqc on the clean reads

2_bwa_align.sh
Aligns clean reads to a reference genome to form sam, converts to bam, sort, index, flagstat (for mapping stats). Includes a quick sanity check at the end to make sure the sorted.raw.bam files are in good shape

3_add_readgroups.sh
Adds readgroup information from a metadata file, where columns specify which read group info should be added

4_dedup.sh
NB Technically this first run of marking duplicates is not necessary because we will run it again per-sample, and that per-sample marking would be enough to achieve the desired result. We only do this round of marking duplicates for QC purposes
Marks duplicates in the bam files

5_merge_sample_bams.sh
NB This merging only needs to happen if you have multiple fastq files for one sample, i.e. one individual sample which has been run across multiple lanes, e.g. sample_1A.fastq sample_1B.fastq. If you have one set of reads per sample you can skip this script (and the next one too)
Merges bams from multiple lanes of sequencing

6_dedup.sh
Marks duplicates in bams from multiple lanes of sequencing

7_recal.sh
Recalibrates the bam files against a "truth-set" of SNPs

Truth-set vcfs are variants for which we have high confidence, and tend to be generated from PCR-free high coverage libraries. If you don't have one of these available, skip this step. In such cases I reccommend calling variants with GATK, and then also calling variants with another program (e.g. Freebayes). When the VCFs of each caller are complete you can intersect them using bedtools intersect and keep the SNPs which were called by both programs. IF variants have been called in both programs, this offers you some confidence.
8_haplotype_caller.sh
This script runs GATK's haplotype caller on your bams, and produces gvcf files for GATK4 CombineGVCFs

NB This script takes the longest time to run
9_consolidate_genotypes.sh
Runs GATK4 GenomicsDBImport and GenotypeGVCFs

10_refine_filter.sh
