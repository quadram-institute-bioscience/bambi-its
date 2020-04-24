##### TREE PLOTS #####

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
par <- add_argument(par, "--outdir", help="output directory", default="./")

# Parse the command line arguments
argv <- parse_args(par)

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

# save variable information into var1, var2,...
i <- 2
while (i > 1 & i <= length(sample_variables(my_physeq_filt_rel))) {
  var <- unlist(sample_variables(my_physeq_filt_rel)[i])
  assign(paste("var", i-1, sep = ""),var)
  i <- i + 1
}

#######################

###### PLOT TREE #######
# Add a new rank, Strain, with the OTU ids
tax_table(my_physeq_filt_rel) <- cbind(tax_table(my_physeq_filt_rel), Strain=taxa_names(my_physeq_filt_rel))
# Define the ranks you want to include
myranks = c("Domain","Phylum","Class","Order", "Family","Genus", "Species", "Strain")
mylabels = apply(tax_table(my_physeq_filt_rel)[, myranks], 1, paste, sep="", collapse="_")
# Add concatenated labels as a new rank after strain
my_physeq_filt_rel_ADAPT = my_physeq_filt_rel
tax_table(my_physeq_filt_rel_ADAPT) = cbind(tax_table(my_physeq_filt_rel), catglab=mylabels)

# plot tree
my_tree <- plot_tree(my_physeq_filt_rel_ADAPT, nodelabf=nodeplotboot(), ladderize="left", label.tips="catglab", text.size = 3, plot.margin=1, size="abundance") + ggtitle("Full tree")
my_tree
ggsave(egg::set_panel_size(my_tree, width=unit(14, "in"), height=unit(10, "in")), file="07_my_tree_abundance.pdf", width = 16, height = 11)

# tip labels
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  my_tree2 <- plot_tree(my_physeq_filt_rel_ADAPT, nodelabf=nodeplotboot(100,0,3), color=x, label.tips="catglab", text.size = 3, ladderize="left", plot.margin=1, size = "abundance") +
    ggtitle("Full tree with colored according to variable")
  print(my_tree2)
  file_name = paste("07_my_tree_abundance_",var,".pdf", sep="")
  ggsave(egg::set_panel_size(my_tree2, width=unit(14, "in"), height=unit(10, "in")), file=file_name, width = 16, height = 11)
}

########################
