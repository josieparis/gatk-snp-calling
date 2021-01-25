#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=168:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=haplotype_caller
#SBATCH --error=haplotype_caller.err.txt 
#SBATCH --output=haplotype_caller.out.txt 
#SBATCH --export=All
#SBATCH --array=1-20%5

### Script to run haplotype caller

# Required modules are: GATK4
module load GATK/4.0.5.1-foss-2018a-Python-3.6.4 SAMtools/1.9-foss-2018b

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in directories if different from the workspace setup
## Also add path to reference
bam_in=$MASTER/SNP_calling/bams/clean_bams
gvcfs=$MASTER/SNP_calling/bams/gvcfs
reference=/gpfs/ts0/home/jrp228/startup/STAR/STAR.chromosomes.release.fasta

## In array ##
insampleID_array=( `cat $samples | cut -f 1` )
insampleID=$bam_in/${insampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## Out array
outsampleID_array=( `cat $samples | cut -f 1` )
outsampleID=$gvcfs/${outsampleID_array[(($SLURM_ARRAY_TASK_ID))]}                                                             

## Run haplotype caller     
gatk --java-options "-Xmx10g" HaplotypeCaller \
-R $reference \
-I ${insampleID}.recal.bam \
-O ${outsampleID}_g.vcf.gz -ERC GVCF
