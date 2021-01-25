#!/bin/bash
#SBATCH -D .
#SBATCH -p pq
#SBATCH --time=72:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH -A Research_Project-T110748
#SBATCH --job-name=five_aside_STAR_refine_filter
#SBATCH --error=FIBR_STAR_refine_filter.err.txt
#SBATCH --output=FIBR_STAR_refine_filter.out.txt
#SBATCH --export=All
#SBATCH --mail-type=END 
#SBATCH --mail-user=mv323@exeter.ac.uk

### Script to filter and refine vcfs ###

module load GATK/4.0.5.1-foss-2018a-Python-3.6.4
module load VCFtools/0.1.16-foss-2018b-Perl-5.28.0

reference=/gpfs/ts0/home/mv323/lustre/start_up_data/STAR/STAR.chromosomes.release.fasta
raw_vcf=/gpfs/ts0/home/mv323/lustre/start_up_data/FIBR/STAR/data/FIBR_gvcfs/FIBR_STAR_cohort_batch_genotyped.g.vcf
DATASET=FIBR_STAR

WORKING_DIR=/gpfs/ts0/home/mv323/lustre/start_up_data/FIBR/STAR/data/FIBR_gvcfs

SNP_filtered=$WORKING_DIR/${DATASET}_SNP_filter.vcf
gatk_filter_flag=$WORKING_DIR/${DATASET}_SNP_gatk_flagged.vcf
gatk_filtered=$WORKING_DIR/${DATASET}_SNP_gatk_filtered
allele_filtered=$WORKING_DIR/${DATASET}_SNP.minmax2.mindp5maxdp200.filtered
maxmiss_filtered=$WORKING_DIR/${DATASET}_SNP.maxmiss50.filtered
sex_maxmiss_filtered=$WORKING_DIR/${DATASET}_SNP.maxmiss10.filtered
final_filtered=$WORKING_DIR/${DATASET}_pop_SNP.gatk.bi.miss.maf.final.filtered.depth4
sex_final_filtered=$WORKING_DIR/${DATASET}_SEXY_pop_SNP.gatk.bi.miss.maf.final.filtered

## Popmaps ## - These have been filtered for low coverage individuals, make sure all are in one directory
POPMAP_DIR=/gpfs/ts0/home/mv323/lustre/popmap/FIBR

## Processing ...

## Select only snps with the "snp_filter"
#gatk --java-options "-Xmx20g" SelectVariants -R $reference -V $raw_vcf --select-type-to-include SNP -O $SNP_filtered

### This gatk step does not actually perform any filtering, it just applies the "snp_filter" tag to SNPs that would pass the filtering
gatk --java-options "-Xmx20g" VariantFiltration -R $reference -V $SNP_filtered -O $gatk_filter_flag --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || HaplotypeScore > 13.0 || MappingQualityRankSum < -12.5" --filter-name "snp_filter"

### This stage actually filters out anything that doesn't have the "snp_filter" tag
vcftools --vcf $gatk_filter_flag --recode --remove-filtered-all --out $gatk_filtered

### Use vcftools to filter remaining SNPS ##

## Retain only biallelic SNPs with a min depth of 5 and max depth of 200

vcftools --vcf $gatk_filtered.recode.vcf --min-alleles 2 --max-alleles 2 --minDP 4 --maxDP 200 --recode --remove-filtered-all --out $allele_filtered

pop_array=(GH GL C T LL UL)
#pop_array=(APHP APLP)
for pop in "${pop_array[@]}"
do

## Split vcf file by population and filter by max missing 50 (for pop gen analyses) and max missing 10% for sex analysis
vcftools --vcf $allele_filtered.recode.vcf --keep $POPMAP_DIR/${pop}.popmap --recode --remove-filtered-all --out ${allele_filtered}.${pop}
vcftools --max-missing 0.5 --vcf $allele_filtered.${pop}.recode.vcf --recode --remove-filtered-all --out ${maxmiss_filtered}.${pop}
#vcftools --max-missing 0.1 --vcf $allele_filtered.${pop}.recode.vcf --recode --remove-filtered-all --out ${sex_maxmiss_filtered}.${pop}

## Do this for every population ^^^ ##

done

## Combine vcfs across poplns using gatk (one for population genetics and one for sex)

module unload GATK/4.0.5.1-foss-2018a-Python-3.6.4
module load GATK/3.8-0-Java-1.8.0_144

## NB Change minimumN6 depending on how many populations you are combining

## Pop gen merging ##
java -Xmx20g -jar $EBROOTGATK/GenomeAnalysisTK.jar -l INFO -T CombineVariants -R $reference \
--variant $maxmiss_filtered.GL.recode.vcf \
--variant $maxmiss_filtered.GH.recode.vcf \
--variant $maxmiss_filtered.C.recode.vcf \
--variant $maxmiss_filtered.T.recode.vcf \
--variant $maxmiss_filtered.LL.recode.vcf \
--variant $maxmiss_filtered.UL.recode.vcf \
--minimumN 10 -o $maxmiss_filtered.merged.vcf

## Filter for minor allele frequency
vcftools --vcf $maxmiss_filtered.merged.vcf --maf 0.01 --recode --remove-filtered-all --out $final_filtered

## Sex merging ##
#java -Xmx20g -jar $EBROOTGATK/GenomeAnalysisTK.jar -l INFO -T CombineVariants -R $reference \
#--variant $sex_maxmiss_filtered.GL.recode.vcf \
#--variant $sex_maxmiss_filtered.GH.recode.vcf \
#--variant $sex_maxmiss_filtered.UQ.recode.vcf \
#--variant $sex_maxmiss_filtered.LO.recode.vcf \
#--variant $sex_maxmiss_filtered.LM.recode.vcf \
#--variant $sex_maxmiss_filtered.UM.recode.vcf \
#--minimumN 6 -o $sex_maxmiss_filtered.merged.vcf

# Filter for minor allele frequency
#vcftools --vcf $sex_maxmiss_filtered.merged.vcf --maf 0.05 --recode --remove-filtered-all --out $sex_final_filtered