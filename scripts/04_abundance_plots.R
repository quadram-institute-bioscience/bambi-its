### ABUNDANCE PLOTS ###

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

### PLOT ABUNDANCES ###

# Family colored but OTU level separation
my_barPhyl_pure <- plot_bar(my_physeq_filt_rel, fill="Phylum") + scale_fill_discrete(na.value="grey90") + ggtitle("Relative abundances at Phylum level") # color by Phylum
my_barClass_pure <- plot_bar(my_physeq_filt_rel, fill="Class") + scale_fill_discrete(na.value="grey90") + ggtitle("Relative abundances at Class level") # color by Class
my_barFam_pure <- plot_bar(my_physeq_filt_rel, fill="Family") + scale_fill_discrete(na.value="grey90") + ggtitle("Relative abundances at Family level")# color by Family
my_barGen_pure <- plot_bar(my_physeq_filt_rel, fill="Genus") + scale_fill_discrete(na.value="grey90") + ggtitle("Relative abundances at Genus level")# color by Genus

# show bar plots
my_barPhyl_pure 
my_barClass_pure
my_barFam_pure
my_barGen_pure

# save bar plots 
ggsave(egg::set_panel_size(my_barPhyl_pure, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(6, "in")), file = "04_my_bar_Phylum.pdf", width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = 8)
ggsave(egg::set_panel_size(my_barClass_pure, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(6, "in")), file = "04_my_bar_Class.pdf", width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = 8)
ggsave(egg::set_panel_size(my_barFam_pure, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(6, "in")), file = "04_my_bar_Family.pdf", width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = 8)
ggsave(egg::set_panel_size(my_barGen_pure, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(6, "in")), file = "04_my_bar_Genus.pdf", width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = 8)

## Create bubble plots

# bubble Class
my_physeq_filt_rel_Class = tax_glom(my_physeq_filt_rel, "Class")
my_barClass <- plot_bar(my_physeq_filt_rel_Class) 
my_barClass$layers <- my_barClass$layers[-1]
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  my_bubbleClass <- my_barClass + 
    geom_point(aes_string(x="Sample", y="Class", size="Abundance", color = x ), alpha = 0.7 ) +
    scale_size_continuous(limits = c(0.001,1)) +
    xlab("Sample") +
    ylab("Class") +
    ggtitle("Relative abundances at Class level") + 
    labs(caption = "Abundances below 0.001 were considered absent") + 
    theme(strip.text = element_text(face="bold", size=14),
          axis.text.x = element_text(color = "black", size = 8, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
          axis.text.y = element_text(color = "black", size = 8, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
          axis.title.x = element_text(color = "black", size = 10, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = 10, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          plot.title = element_text(size = 12),
          plot.caption = element_text(size = 6),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8))
  print(my_bubbleClass)
  file_name = paste("04_my_bubble_Class_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(my_bubbleClass, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(ntaxa(my_physeq_filt_rel_Class) / 5, "in")), file = file_name, width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = (ntaxa(my_physeq_filt_rel_Class) / 5) + 4)
}


# bubble Family
my_physeq_filt_rel_Fam = tax_glom(my_physeq_filt_rel, "Family")
my_barFam <- plot_bar(my_physeq_filt_rel_Fam) 
my_barFam$layers <- my_barFam$layers[-1]
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  my_bubbleFam <- my_barFam + 
    geom_point(aes_string(x="Sample", y="Family", size="Abundance", color = x ), alpha = 0.7) +
    scale_size_continuous(limits = c(0.001,1)) +
    xlab("Sample") +
    ylab("Family") +
    ggtitle("Relative abundances at Family level") + 
    labs(caption = "Abundances below 0.001 were considered absent") + 
    theme(strip.text = element_text(face="bold", size=14),
          axis.text.x = element_text(color = "black", size = 8, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
          axis.text.y = element_text(color = "black", size = 8, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
          axis.title.x = element_text(color = "black", size = 10, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = 10, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          plot.title = element_text(size = 12),
          plot.caption = element_text(size = 6),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8))
  print(my_bubbleFam)
  file_name = paste("04_my_bubble_Family_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(my_bubbleFam, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(ntaxa(my_physeq_filt_rel_Fam) / 5, "in")), file = file_name, width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = (ntaxa(my_physeq_filt_rel_Fam) / 5) + 2)
}

# bubble Genus
my_physeq_filt_rel_Gen = tax_glom(my_physeq_filt_rel, "Genus")
my_barGen <- plot_bar(my_physeq_filt_rel_Gen) 
my_barGen$layers <- my_barGen$layers[-1]
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  my_bubbleGen <- my_barGen + 
    geom_point(aes_string(x="Sample", y="Genus", size="Abundance", color = x ), alpha = 0.7) +
    scale_size_continuous(limits = c(0.001,1)) +
    xlab("Sample") +
    ylab("Genus") +
    ggtitle("Relative abundances at Genus level") + 
    labs(caption = "Abundances below 0.001 were considered absent") + 
    theme(strip.text = element_text(face="bold", size=14),
          axis.text.x = element_text(color = "black", size = 8, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
          axis.text.y = element_text(color = "black", size = 8, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
          axis.title.x = element_text(color = "black", size = 10, angle = 0, hjust = .5, vjust = 0, face = "plain"),
          axis.title.y = element_text(color = "black", size = 10, angle = 90, hjust = .5, vjust = .5, face = "plain"),
          plot.title = element_text(size = 12),
          plot.caption = element_text(size = 6),
          legend.title = element_text(size = 10),
          legend.text = element_text(size = 8))
  print(my_bubbleGen)
  file_name = paste("04_my_bubble_Genus_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(my_bubbleGen, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(ntaxa(my_physeq_filt_rel_Gen) / 5, "in")), file = file_name, width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = (ntaxa(my_physeq_filt_rel_Gen) / 5) + 2)
}


# bubble Species
# test if species exist
bla <- as.vector(tax_table(my_physeq_filt_rel)[,"Species"])
if ( sum(grep('*', bla)) == 0 ) {
  print("no Species level affiliation")
} else {
  my_physeq_filt_rel_Spec = tax_glom(my_physeq_filt_rel, "Species")
  my_barSpec <- plot_bar(my_physeq_filt_rel_Spec) 
  my_barSpec$layers <- my_barSpec$layers[-1]
  for ( n in 1:(i-2) ) {
    var <- paste("var", n, sep="")
    x <- get(var)
    my_bubbleSpec <- my_barSpec + 
      geom_point(aes_string(x="Sample", y="Species", size="Abundance", color = x ), alpha = 0.7) +
      scale_size_continuous(limits = c(0.001,1)) +
      xlab("Sample") +
      ylab("Species") +
      ggtitle("Relative abundances at Species level") + 
      labs(caption = "Abundances below 0.001 were considered absent") + 
      theme(strip.text = element_text(face="bold", size=14),
            axis.text.x = element_text(color = "black", size = 8, angle = 90, hjust = 1, vjust = 0.5, face = "plain"),
            axis.text.y = element_text(color = "black", size = 8, angle = 0, hjust = 1, vjust = 0.5, face = "plain"),
            axis.title.x = element_text(color = "black", size = 10, angle = 0, hjust = .5, vjust = 0, face = "plain"),
            axis.title.y = element_text(color = "black", size = 10, angle = 90, hjust = .5, vjust = .5, face = "plain"),
            plot.title = element_text(size = 12),
            plot.caption = element_text(size = 6),
            legend.title = element_text(size = 10),
            legend.text = element_text(size = 8))
    print(my_bubbleSpec)
    file_name = paste("04_my_bubble_Spec_",var, ".pdf", sep="")
    ggsave(egg::set_panel_size(my_bubbleSpec, width=unit(nsamples(my_physeq_filt_rel) / 8, "in"), height=unit(ntaxa(my_physeq_filt_rel_Spec) / 5, "in")), file = file_name, width = (nsamples(my_physeq_filt_rel) / 8) + 5, height = (ntaxa(my_physeq_filt_rel_Spec) / 5) + 2)
  }
}


#######################