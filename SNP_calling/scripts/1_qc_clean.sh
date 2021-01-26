#!/bin/bash
#SBATCH -D .
#SBATCH -p sq
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH -A <research_project>
#SBATCH --job-name=qc_clean
#SBATCH --error=logs/qc_clean.err.txt
#SBATCH --output=logs/qc_clean.out.txt
#SBATCH --export=All
#SBATCH --array=1-10

## Load your system modules
# Required modules are: FastQC, Python2, Trim_Galore
module purge
module load FastQC/0.11.7-Java-1.8.0_162 Python/2.7.9-intel-2016b Trim_Galore/0.4.5-foss-2016b

## Set your master path
MASTER=<path>

## Fill in path for population specific metadata ##
metadata=$MASTER/SNP_calling/metadata.tsv

## Fill in directories if different from the workspace setup
raw_reads=$MASTER/SNP_calling/reads/raw_reads
clean_reads=$MASTER/SNP_calling/reads/clean_reads
fastqc_raw=$MASTER/SNP_calling/reads/raw_reads/fastqc
fastqc_clean=$MASTER/SNP_calling/reads/clean_reads/fastqc
                                                                                                                                                   
## Create an array to hold all of the files within the raw reads location
read1_array=( `cat $metadata | cut -f 3` )
read1=$raw_reads/${read1_array[(($SLURM_ARRAY_TASK_ID))]}

read2_array=( `cat $metadata | cut -f 4` )
read2=$raw_reads/${read2_array[(($SLURM_ARRAY_TASK_ID))]}

out_array=( `cat $metadata | cut -f 2` )
out=$clean_reads/${out_array[(($SLURM_ARRAY_TASK_ID))]}


## Testing that all variables are working correctly                                                                                                                                                                  
echo "read1" $read1
echo "read2" $read2
echo "output directory" $clean_reads

## Run fastqc on raw reads                                                                                               
fastqc ${read1} ${read2} -o $fastqc_raw

## Run trim_galore default settings (but adjust adaptors if needed)      
trim_galore -q 20 --path_to_cutadapt cutadapt -o $clean_reads --paired ${read1} ${read2}

## you may need to change the suffix of these files, depending on your read suffix. Alternatively, run fastqc and trimgalore, add the clean reads to your metadata and then create another array with the clean reads to be used here
## Run fastqc on clean reads
fastqc ${out}_r1_val_1.fq.gz ${out}_r2_val_2.fq.gz -o $fastqc_raw


