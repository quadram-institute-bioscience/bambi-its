### CREATE PHYLOSEQ OBJECT ###

# FIRST THINGS FIRST #

# create stdout log file 
# zz <- file("01_import_phyloseq_object.Rout", open="wt")
# sink(zz)
# sink(zz, type="message")

# load required packages
if (!requireNamespace("BiocManager", quietly = TRUE)){
  install.packages("BiocManager")}

list.of.bioc <- c("phyloseq", "ape", "gtools", "plyr", "dplyr","tibble")
new.packages <- list.of.bioc[!(list.of.bioc %in% installed.packages()[,"Package"])]
if(length(new.packages)) BiocManager::install(new.packages)

library("phyloseq")
library("gtools")
library("plyr")
library("dplyr")
library("argparser")
library("tibble")
library("ape")

# Create a parser for commandline arguments
par <- arg_parser("relative abundances features/OTUs")

# Add command line arguments
par <- add_argument(par, "--outdir", help="output directory", default="./")
par <- add_argument(par, "--feature", help="tab-delimited feature/OTU table")
par <- add_argument(par, "--tax", help="tab-delimited taxonomy file including header")
par <- add_argument(par, "--tree", help="tree in newick format")
par <- add_argument(par, "--meta", help="tab-delimited metadata file")
par <- add_argument(par, "--sampleID", help="Column name or number (e.g. 1) with the sample ID (e.g. SampleName)")
par <- add_argument(par, "--mcat", help="comma-separated (e.g. Time,Treatment) column headers of metadata to include in plots")

# Parse the command line arguments
argv <- parse_args(par)
MCAT = unlist(strsplit(argv$mcat,","))

#######################

##### DATA IMPORT #####

# import OTU data
in_otu = as.matrix(read.table(argv$feature, header=TRUE, sep="\t", row.names = 1, comment.char=""))
head(in_otu)
class(in_otu)
ncol(in_otu)

# import taxonomy
in_tax = as.matrix(read.table(argv$tax, header=TRUE, sep=",", row.names = 1, fill=TRUE, na.strings=c("","NA","d__","p__","c__","o__","f__","g__","s__"), comment.char=""))
head(in_tax)
class(in_tax)
ncol(in_tax)

# import tree
in_tree <- read.tree(file = argv$tree)
class(in_tree)

# import metadata
metaIn <- argv$meta
metaIn = read.table(metaIn, header=TRUE, sep="\t", comment.char="")
metaIn_tibble = tibble(metaIn)
metaIn_tibble = metaIn_tibble %>% filter( !grepl("^#",metaIn_tibble[[1]]))

if ( is.numeric(argv$sampleID) == TRUE) {
  SAMPLEID = argv$sampleID
} else {
  SAMPLEID = grep(argv$sampleID, colnames(metaIn_tibble))
}
print(SAMPLEID)
metaIn_tibble$rName = metaIn_tibble[[SAMPLEID]]
metaIn_tibble = metaIn_tibble %>% column_to_rownames('rName')
metaIn_tibble = metaIn_tibble %>% rename(sampleIDs = all_of(SAMPLEID))
metaIn_tibble = metaIn_tibble %>% select(sampleIDs, all_of(MCAT))
in_metad = sample_data(metaIn_tibble)
class(in_metad)
head(in_metad)

my_OTU = otu_table(in_otu, taxa_are_rows = TRUE)
my_TAX = tax_table(in_tax)
head(my_OTU)
head(my_TAX)

# combine to create phyloseq object
my_physeq = phyloseq(my_OTU, my_TAX, in_metad, in_tree)
my_physeq

# set working directory
dir.create(file.path(argv$outdir), showWarnings = FALSE)
setwd(file.path(argv$outdir))

# save phyloseq object as rds
saveRDS(my_physeq, file = "my_physeq.rds")



