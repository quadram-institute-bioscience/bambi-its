# Run the phyloseq R scripts with the parameters chosen for this dataset
# this should be run in the script directory using: ./run_phyloseq_ITS.sh

# cd bambi-its/scripts

# output and data directory can be changed
OUT="../data/phyloseq_out"
DATA="../data"

Rscript ./phyloseq_Rscripts/01_import_phyloseq_object.R \
	--feature ${DATA}/feature-table.tsv \
	--tax ${DATA}/taxonomy.csv \
	--tree ${DATA}/asv.tre \
	--meta ${DATA}/metadata.tsv \
	--mcat Months,Sex,Delivery \
	--sampleID SampleName \
	--outdir ${OUT}

Rscript ./phyloseq_Rscripts/02_alpha_diversity.R -p ${OUT}/my_physeq.rds --outdir ${OUT}

Rscript ./phyloseq_Rscripts/03_pre-processing.R -p ${OUT}/my_physeq.rds -t 10000 --min 0.05 --outdir ${OUT}

Rscript ./phyloseq_Rscripts/04_abundance_plots.R -p ${OUT}/my_physeq_filtered.rds --outdir ${OUT}

Rscript ./phyloseq_Rscripts/05_beta_diversity.R -p ${OUT}/my_physeq_filtered.rds --outdir ${OUT}

Rscript ./phyloseq_Rscripts/06_heatmaps.R -p ${OUT}/my_physeq_filtered.rds --label Phylum,Months --outdir ${OUT}

Rscript ./phyloseq_Rscripts/07_tree_plots.R -p ${OUT}/my_physeq_filtered.rds --outdir ${OUT}

rm ${OUT}/Rplots.pdf

pdfunite ${OUT}/*.pdf ${OUT}/all_combi.pdf
