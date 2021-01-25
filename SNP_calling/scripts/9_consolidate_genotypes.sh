#!/bin/bash
#SBATCH -D . 
#SBATCH -p pq  
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=2
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=FIBR_STAR_batch_newQual
#SBATCH --error=FIBR_STAR_batch_newQual.err.txt
#SBATCH --output=FIBR_STAR_batch_newQual.out.txt
#SBATCH --export=All
#SBATCH --array=1-267%20

### Script to combine gVCFs and then genotype across the cohort

# Required modules are: GATK4, bcftools
module load GATK/4.0.5.1-foss-2018a-Python-3.6.4 
module load BCFtools/1.9-foss-2018b

## Set your master path
MASTER=/gpfs/ts0/home/jrp228/NERC/people/josie/github_test/gatk-snp-calling

## Fill in directories if different from the workspace setup
## Also add path to reference
gvcfs=$MASTER/SNP_calling/bams/gvcfs
output_vcfs=$MASTER/SNP_calling/vcfs/intervals
reference=/gpfs/ts0/home/jrp228/startup/STAR/STAR.chromosomes.release.fasta

## Name your dataset
DATASET=FIBR_STAR

# make the command for variants
infiles=(`ls -1 ${gvcfs}/_g.vcf.gz`)
let len=${#infiles[@]}-1
cmd=""
for i in `seq 0 $len`
do
    cmd+="--variant ${infiles[$i]} "
done

# Fetch the interval of interest
interval=$(awk '{print $1}' ${reference}.fai | sed "${SLURM_ARRAY_TASK_ID}q;d")
echo $interval
# Remove if done already
rm -rf $gvcfs/INTERVAL_${interval}_db

# Make database
gatk --java-options "-Xmx16g -Xms4g" GenomicsDBImport \
    $cmd \
    --genomicsdb-workspace-path $gvcfs/INTERVAL_${SLURM_ARRAY_TASK_ID}_db \
    --reader-threads 2 \
    --intervals $interval

# Genotype
cd $output_vcfs

gatk --java-options "-Xmx16g -Xms4g" GenotypeGVCFs \
    -R $reference \
    -V gendb://INTERVAL_${SLURM_ARRAY_TASK_ID}_db \
    -O ${interval}.vcf.gz

# Tidy 
rm -rf *INTERVAL_${SLURM_ARRAY_TASK_ID}_db*

### Run this when the above is all good
ls $output_vcfs/intervals/*vcf.gz >> batch_filter.txt
grep -Fxf batch_filter.txt batch_inputs.txt > batch_inputs_2.txt
bcftools concat -o $output_vcfs/${DATASET}_cohort_batch_genotyped.g.vcf -f $output_vcfs/intervals/batch_inputs_2.txt

