#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=master_merge_bams 
#SBATCH --error=master_merge_bams_C.err.txt 
#SBATCH --output=master_merge_bams_C.out.txt 
#SBATCH --export=All
#SBATCH --array=1-40%10


### Script to merge bams from multiple fastq reads

## Load your system modules
# Required modules are: picard tools
module load picard/2.6.0-Java-1.8.0_131

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in directories if different from the workspace setup
bam_path=$MASTER/SNP_calling/bams/interim_bams

## Fill in path for population specific metadata
metadata=$MASTER/SNP_calling/metadata.tsv

### The sample IDs are extracted from the metadata
i=$(cut -f 1 $matedata | tail -n+2 | uniq | sed -n "${SLURM_ARRAY_TASK_ID}p")

# Find all bams for this individual and merge
    mfiles=`ls -1 ${bam_path}/${i}_*sorted.dups.bam`
    cmd=""
    for file in $mfiles
    do
	cmd+="I=$file "
    done
    jcmd="java -Xmx10g -jar $EBROOTPICARD/picard.jar MergeSamFiles $cmd O=$bam_path/${i}.merged.bam TMP_DIR=/gpfs/ts0/scratch/mv323/tmp"
   $jcmd

