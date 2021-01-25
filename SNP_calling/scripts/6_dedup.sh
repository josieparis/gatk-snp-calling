#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=master_dedup_merged 
#SBATCH --error=master_dedup_merged.err.txt 
#SBATCH --output=master_dedup_merged.out.txt 
#SBATCH --export=All
#SBATCH --array=1-50%10


### Script to dedup merged bams

## Load your system modules
# Required modules are: picard tools
module load picard/2.6.0-Java-1.8.0_131
module load picard/2.6.0-Java-1.8.0_131

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in directories if different from the workspace setup
bam_path=$MASTER/SNP_calling/bams/interim_bams

## Fill in path for population specific metadata
metadata=$MASTER/SNP_calling/metadata.tsv

## In array ##
insampleID_array=( `cat $samples |  cut -f 1` )
insampleID=$bam_path/${insampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## Out array ##
outsampleID_array=( `cat $samples | cut -f 1` )
outsampleID=$bam_path/${outsampleID_array[(($SLURM_ARRAY_TASK_ID))]}


## This just catches the array in case it's running for a value with no individual (this screws with the outputs)
IND_N=$(cut -f1 $metadata | tail -n+2 | uniq | awk 'NF > 0' | wc -l)

if [ $SLURM_ARRAY_TASK_ID -le $IND_N ]
then

## Mark duplicates in the merged bam files ##
java -Xmx10g -jar $EBROOTPICARD/picard.jar MarkDuplicates \
I=$insampleID.merged.bam \
O=$outsampleID.merged.sorted.dups.bam \
METRICS_FILE=$outsampleID.merged.sorted.dups.metrics.txt \
REMOVE_DUPLICATES=true \
VALIDATION_STRINGENCY=LENIENT AS=true \
TMP_DIR=/gpfs/ts0/scratch/mv323/tmp

## Index the Deduped merged bam files
java -Xmx10g -jar $EBROOTPICARD/picard.jar BuildBamIndex \
I=$outsampleID.merged.sorted.dups.bam VALIDATION_STRINGENCY=LENIENT


fi
