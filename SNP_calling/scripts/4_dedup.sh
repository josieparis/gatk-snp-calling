#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A <research_project>
#SBATCH --job-name=index_dedup_master 
#SBATCH --error=index_dedup_master.err.txt 
#SBATCH --output=index_dedup_master.out.txt 
#SBATCH --export=All
#SBATCH --array=1-125%20

### Script to mark duplicates and remove duplicates

## Load your system modules
# Required modules are: picard tools
module purge
module load picard/2.6.0-Java-1.8.0_131

## Set your master path
MASTER=<path>

## Fill in directories if different from the workspace setup
bam_in=$MASTER/SNP_calling/bams/interim_bams
bam_out=$MASTER/SNP_calling/bams/interim_bams

## Picard path:
EBROOTPICARD=<path_to_picard>

## Fill in path for population specific metadata
metadata=$MASTER/SNP_calling/metadata.tsv

## In array ##
insampleID_array=( `cat $metadata | cut -f 2` )
insampleID=$bam_in/${insampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## Out array 
outsampleID_array=( `cat $metadata | cut -f 2` )
outsampleID=$bam_out/${outsampleID_array[(($SLURM_ARRAY_TASK_ID))]}


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

