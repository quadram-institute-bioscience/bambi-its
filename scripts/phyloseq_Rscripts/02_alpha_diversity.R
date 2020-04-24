### ALPHA DIVERSITY ###

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
par <- arg_parser("alpha diversity")
# Add command line arguments
par <- add_argument(par, "--phyloseq", help="RDS file of phyloseq object", default = "my_physeq.rds")
par <- add_argument(par, "--outdir", help="output directory", default="./")
# Parse the command line arguments
argv <- parse_args(par)

# create stdout log file 
#zz <- file("02_alpha_diversity", open="wt")
#sink(zz)
#sink(zz, type="message")

# import phyloseq object
my_physeq<-readRDS(argv$phyloseq)
setwd(file.path(argv$outdir))

# set plotting theme
theme_set(theme_bw())

# save variable information into var1, var2,...
i <- 2
while (i > 1 & i <= length(sample_variables(my_physeq))) {
  var <- unlist(sample_variables(my_physeq)[i])
  assign(paste("var", i-1, sep = ""),var)
  i <- i + 1
}

#######################

### ALPHA DIVERSITY ###

my_physeq

# trim OTUs that are not present in any sample
print('==> Remove OTUs that are not present (0 counts) in any sample')
my_0pruned <- prune_taxa(taxa_sums(my_physeq) > 0, my_physeq)

# plot alpha-diversity on UNFILTERED DATA (all included measures)
#my_alpha_all <- plot_richness(my_physeq) + ggtitle("Figure | alpha diversity - overview all measures") + labs(caption = "alpha diversity calculated on unfiltered data (only OTUs with 0 counts in all samples were removed)") 
#my_alpha_all  

my_alpha_all_plot <- plot_richness(my_0pruned, measures = c("Observed", "Chao1", "ACE", "Shannon", "Simpson", "InvSimpson")) + ggtitle("Figure | alpha diversity - overview all measures") + labs(caption = "alpha diversity calculated on unfiltered data (only OTUs with 0 counts in all samples were removed)") +
  theme(strip.text = element_text(face="bold", size=14),
        axis.text.x = element_text(color = "black", size = 7, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
        axis.text.y = element_text(color = "black", size = 14, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
        axis.title.x = element_text(color = "black", size = 14, angle = 0, hjust = .5, vjust = 0, face = "plain"),
        axis.title.y = element_text(color = "black", size = 14, angle = 90, hjust = .5, vjust = .5, face = "plain"),
        plot.title = element_text(size = 18))

ggsave(egg::set_panel_size(my_alpha_all_plot, width=unit(nsamples(my_physeq) / 12, "in"), height=unit(6, "in")), file = "02_my_alpha_all.pdf", width = (nsamples(my_physeq) / 12) * 8, height = 8)


# make a graph for every distance measure
my_alpha_comb_list <- NULL
for( alp in c("Observed", "Chao1", "ACE", "Shannon", "Simpson", "InvSimpson") ){
  my_alpha_comb_plot <- NULL
  my_alpha_comb_plot <- plot_richness(my_0pruned, x="sampleIDs", measures=alp)
  my_alpha_comb_plot <- my_alpha_comb_plot + ggtitle(paste("Figure | alpha diversity* according to the ", alp, " measure", sep="")) +
    labs(caption = "*calculated on unfiltered data; OTUs with 0 counts in all samples were removed")
  my_alpha_comb_plot$layers <- my_alpha_comb_plot$layers[-1]  # remove first layer
  my_alpha_comb_list[[alp]] = my_alpha_comb_plot
}

# plot every distance measure for every variable and save into separate plots
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  pal2 <- my_alpha_comb_list[["Chao1"]] + 
    geom_point(aes_string(color=x), size=3, alpha = 0.7) +
    guides(color=guide_legend(title=x)) +
    theme(strip.text = element_text(face="bold", size=10),
          axis.text.x = element_text(color = "black", size = 8, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
          axis.text.y = element_text(color = "black", size = 8, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
          axis.title.x = element_text(color = "black", size = 10, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = 10, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          plot.title = element_text(size = 12),
          plot.caption = element_text(size = 6),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8))
  file_name = paste("02_my_alpha_", var, ".pdf", sep="")
  print(pal2)
  ggsave(egg::set_panel_size(pal2, width=unit(nsamples(my_physeq) / 10, "in"), height=unit(6, "in")), file = file_name, width = (nsamples(my_physeq) / 10) + 4, height = 8)
}  

#######################