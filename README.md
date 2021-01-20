# gatk-snp-calling
Full GATK SNP calling pipeline

This set of scripts take raw illumina whole-genome sequencing reads as input to produce a filtered VCF file

These scripts were written for a PBS batch cluster system and have since been rewritten for a SLURM batch system. I also have older ones available for SGE, which I can send by request (they may need some updating)

#### These scripts have been used to create VCF files in the following publications:

Fraser BA, Whiting JR, Paris JR, Weadick CJ, Parsons PJ, Charlesworth D, Bergero R, Bemm F, Hoffmann M, Kottler VA, Liu C, Dreyer C, Weigel D (2020). Improved reference genome uncovers novel sex-linked regions in the guppy (Poecilia reticulata). Genome Biology and Evolution, evaa187. https://doi.org/10.1093/gbe/evaa187

Whiting JR, Paris JR, van der Zee MJ, Parsons, PJ, Weigel D, Fraser BA. Drainage-structuring of ancestral variation and a common functional pathway shape limited genomic convergence in natural high- and low-predation guppies. bioRxiv: https://doi.org/10.1101/2020.10.14.339333

And more to follow! 


#### For these scripts to work, you need to set up a neat waterfall workspace

![alt text](https://github.com/josieparis/gatk-snp-calling/blob/image.jpg?raw=true)


