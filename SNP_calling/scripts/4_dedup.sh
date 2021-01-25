#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=index_dedup_master 
#SBATCH --error=index_dedup_master.err.txt 
#SBATCH --output=index_dedup_master.out.txt 
#SBATCH --export=All
#SBATCH --array=1-125%20

### Script to mark duplicates and remove duplicates

## Load your system modules
# Required modules are: picard tools
module load picard/2.6.0-Java-1.8.0_131

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in directories if different from the workspace setup
bam_in=$MASTER/SNP_calling/bams/interim_bams
bam_out=$MASTER/SNP_calling/bams/interim_bams

## Fill in path for population specific metadata
metadata=$MASTER/SNP_calling/metadata.tsv

## In array ##
insampleID_array=( `cat $metadata | cut -f 2` )
insampleID=$bam_in/${insampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## Out array 
outsampleID_array=( `cat $metadata | cut -f 2` )
outsampleID=$bam_out/${outsampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## This just catches the array in case it's running for a value with no individual (this screws with the outputs)
IND_N=$(cut -f1 $metadata | tail -n+2 | uniq | awk 'NF > 0' | wc -l)

if [ $SLURM_ARRAY_TASK_ID -le $IND_N ]
then

## Run picardtools MarkDuplicates
java -Xmx10g -jar $EBROOTPICARD/picard.jar MarkDuplicates \
I=$insampleID.sorted.rg.bam \
O=$outsampleID.sorted.dups.bam \
METRICS_FILE=$outsampleID.metrics.txt \
REMOVE_DUPLICATES=true \
VALIDATION_STRINGENCY=LENIENT AS=true \
TMP_DIR=/gpfs/ts0/scratch/jrp228/tmp
## optional = TMP_DIR=<scratch_space>

## Index the deduped bam files
java -Xmx10g -jar $EBROOTPICARD/picard.jar BuildBamIndex \
I=$outsampleID.sorted.dups.bam VALIDATION_STRINGENCY=LENIENT

fi
