#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq
#SBATCH --time=1:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4  
#SBATCH -A <research project>
#SBATCH --job-name=bwa_align 
#SBATCH --error=logs/bwa_align.err.txt  
#SBATCH --output=logs/bwa_align.out.txt  
#SBATCH --export=All
#SBATCH --array=1-10
###SBATCH --array=1-20%5

### Script to run a bwa mem, bam and sort bam 

# Load modules
# Required modules are: bwa, samtools
module load BWA/0.7.17-foss-2018a
module load SAMtools/1.3.1-foss-2016a 

## Set your master path
MASTER=<path>

## Fill in directories if different from the workspace setup
## Also add path to indexed reference
reference=$MASTER/reference.fasta
input_reads=$MASTER/SNP_calling/reads/clean_reads
bam_dir=$MASTER/SNP_calling/bams/raw_bams

## Fill in path for population specific metadata
metadata=$MASTER/SNP_calling/metadata.tsv

## Read 1 array ##
read1_array=(`cat $metadata | cut -f 3`)
read1=$input_reads/${read1_array[(($SLURM_ARRAY_TASK_ID))]}

## Read 2 array ##
read2_array=( `cat $metadata | cut -f 4` )
read2=$input_reads/${read2_array[(($SLURM_ARRAY_TASK_ID))]}

## Output array ##
out_array=( `cat $metadata | cut -f 2` )
bam_out=$bam_dir/${out_array[(($SLURM_ARRAY_TASK_ID))]}

echo "reference" $reference
echo "read1" $read1
echo "read2" $read2
echo "alignment" ${bam_out}.unsorted.raw.sam

## Align with bwa mem using 4 cores. Again, make sure the read name prefixes match in the metadata
bwa mem -t 4 $reference $read1 $read2 > $bam_out.unsorted.raw.sam

## Convert bam to sam, sort bam, index, flagstat
samtools view -bS $bam_out.unsorted.raw.sam > $bam_out.unsorted.raw.bam
samtools sort $bam_out.unsorted.raw.bam -o $bam_out.sorted.raw.bam
samtools index $bam_out.sorted.raw.bam
samtools flagstat $bam_out.sorted.raw.bam > $bam_out.mappingstats.txt

# ## Remove the sam and unsorted bam files
rm $bam_dir/*.sam
rm $bam_dir/*.unsorted.raw.bam

## To check that the bams are not corrupted, run (in the directory where the bams are):

# samtools quickcheck -v *.sorted.raw.bam > bad_bams.fofn   && echo 'all ok' || echo 'some files failed check, see bad_bams.fofn'

