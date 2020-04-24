###### HEATMAPS ######

# FIRST THINGS FIRST #

# load required packages
if (!requireNamespace("BiocManager", quietly = TRUE)){
  install.packages("BiocManager")}

list.of.bioc <- c("phyloseq", "ggplot2", "ape", "gtools", "plyr", "gridExtra", "egg")
new.packages <- list.of.bioc[!(list.of.bioc %in% installed.packages()[,"Package"])]
if(length(new.packages)) BiocManager::install(new.packages)

library("phyloseq")
library("ggplot2")
library("ape")
library("gtools")
library("plyr")
library("gridExtra")
library("egg")
library("argparser")

# Create a parser
par <- arg_parser("abundance plots")
# Add command line arguments
par <- add_argument(par, "--phyloseq", help="RDS file of pre-processed phyloseq object", default = "my_physeq_filtered.rds")
par <- add_argument(par, "--label", help="Choose a taxonomy rank (y-axis) as heatmap label and a metadata category (x-axis) e.g. Phylum,Sex", default = "")
par <- add_argument(par, "--outdir", help="output directory", default="./")

# Parse the command line arguments
argv <- parse_args(par)
print(nchar(argv$label))
if ( nchar(argv$label) > 0 ) {
  LABEL = unlist(strsplit(argv$label,","))
} 

# create stdout log file 
# zz <- file("03.log", open="wt")
# sink(zz)
# sink(zz, type="message")

#######################

##### IMPORT DATA #####

# import phyloseq object with pre-processed / filtered data
my_physeq_filt_rel<-readRDS(argv$phyloseq)
setwd(file.path(argv$outdir))

# set plotting theme
theme_set(theme_bw())

##### REPORT DATA #####

print('phyloseq object:')
my_physeq_filt_rel
otu_table(my_physeq_filt_rel)[1:5]

#######################

####### HEATMAP #######

# standard heatmap
my_heat = plot_heatmap(my_physeq_filt_rel, na.value="black") + ggtitle("Standard heatmap")
my_heat
ggsave(my_heat, file="06_my_heat.png", width = 8, height = 7)

# NMDS ordination on the (default) bray-curtis distance.
my_heat_NMDSbray = plot_heatmap(my_physeq_filt_rel, "NMDS", "bray", "sampleIDs", na.value="black") + ggtitle("NMDS ordination on bray-curtis distance OTU abundance per sample")
my_heat_NMDSbray 
ggsave(my_heat_NMDSbray, file="06_my_heat_NMDSbray.png", width = 8, height = 7)

# standard heatmap function in R using hierarchical clustering
png('06_my_heat_hier.png', width = 800, height = 700, units='px')
heatmap(otu_table(my_physeq_filt_rel))
dev.off()

# heatmap with user inpout labeling
if ( nchar(argv$label) > 0 ) {
  my_heat_NMDSbrayMOD = plot_heatmap(my_physeq_filt_rel, "NMDS", "bray", LABEL[[2]], LABEL[[1]], na.value="black") + ggtitle("NMDS ordination on bray-curtis distance OTU abundance per sample")
  my_heat_NMDSbrayMOD
  ggsave(my_heat_NMDSbrayMOD, file="06_my_heat_NMDSbray_meta.png", width = 8, height = 7)
}

#######################
