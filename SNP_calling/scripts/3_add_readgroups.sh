#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=00:60:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A <Research_Project>
#SBATCH --job-name=add_readgroups 
#SBATCH --error=add_readgroups.err.txt
#SBATCH --output=add_readgroups.out.txt 
#SBATCH --export=All
#SBATCH --array=1-3

### Script to add readgroups to bams

## Load your system modules
# Required modules are picard tools
module load picard/2.6.0-Java-1.8.0_131

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in path for population specific metadata ##
metadata=$MASTER/SNP_calling/metadata.tsv
bam_in=$MASTER/SNP_calling/bams/raw_bams
bam_out=$MASTER/SNP_calling/bams/interim_bams

# Metadata file for each population
# 1 simple_ID
# 2 sample_ID
# 3 read1
# 4 read2
# 5 instrument
# 6 flowcell
# 7 lane
# 8 barcode
# 9 sex
# 10 run_num
# 11 seq_num

simpleID_array=( `cat $metadata | cut -f 1` )
simpleID=${simpleID_array[(($SLURM_ARRAY_TASK_ID))]}

instrument_array=( `cat $metadata | cut -f 5` )
instrument=${instrument_array[(($SLURM_ARRAY_TASK_ID))]}

seqnum_array=( `cat $metadata | cut -f 11` )
seqnum=${seqnum_array[(($SLURM_ARRAY_TASK_ID))]}

flowcell_array=( `cat $metadata | cut -f 6` )
flowcell=${flow_cell_array[(($SLURM_ARRAY_TASK_ID))]}

lane_array=( `cat $metadata | cut -f 7` )
lane=${lane_array[(($SLURM_ARRAY_TASK_ID))]}

barcode_array=( `cat $metadata | cut -f 8` )
barcode=${barcode_array[(($SLURM_ARRAY_TASK_ID))]}

## In array
insampleID_array=( `cat $metadata | cut -f 2` )
insampleID=$bam_in/${insampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## Out array
outsampleID_array=( `cat $metadata | cut -f 2` )
outsampleID=$bam_out/${outsampleID_array[(($SLURM_ARRAY_TASK_ID))]}

## NB  $EBROOTPICARD is the path to your install of picard
## Run picard tools AddreplaceRGs
java -Xmx10g -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
I=${insampleID}.sorted.raw.bam \
O=${outsampleID}.sorted.rg.bam \
RGSM=${simpleID} \
RGLB=${simpleID}.${seqnum} \
RGID=${flowcell}.${lane} \
RGPU=${flowcell}${lane}.${barcode} \
RGPL=${instrument} \

## Index the readgroup bam files
java -Xmx10g  -jar $EBROOTPICARD/picard.jar BuildBamIndex \
I=${outsampleID}.sorted.rg.bam VALIDATION_STRINGENCY=LENIENT
