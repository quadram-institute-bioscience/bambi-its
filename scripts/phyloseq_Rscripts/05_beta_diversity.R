### BETA DIVERSITY ###

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

#### BETA DIVERSITY ####

# list distance methods
dist_methods <- unlist(distanceMethodList)

# check if tree was supplied and remove distance methods Unifrac and DPCoA if no tree was provided
if ( class(phy_tree(my_physeq_filt_rel)) == "phylo" ) {
  print("cool, you provided a tree")
  # remove use defined method
  dist_methods = dist_methods[-which(dist_methods=="ANY")]
} else {
  print("you did not provide a tree - excluding unifrac and weighted unifrac")
  # remove use defined method and unifrac methods
  dist_methods = dist_methods[-which(dist_methods=="ANY")]
  dist_methods = dist_methods[-which(dist_methods=="unifrac")]
  dist_methods = dist_methods[-which(dist_methods=="wunifrac")]
  dist_methods = dist_methods[-which(dist_methods=="dpcoa")]
}

# print distance methods
print(dist_methods)

# loop through each distance method, save each plot to a list called my_dist_list
my_dist_list <- vector("list", length(dist_methods))
names(my_dist_list) = dist_methods
for( d in dist_methods ){
  set.seed(2)
  # Calculate distance matrix
  iDist <- distance(my_physeq_filt_rel, method=d)
  # Calculate MDS ordination
  iMDS  <- ordinate(my_physeq_filt_rel, "MDS", distance=iDist)
  # make plot
  dist_MDS <- NULL
  dist_MDS <- plot_ordination(my_physeq_filt_rel, iMDS) + 
    ggtitle(paste("MDS using distance method ", d, sep=""))
  # Save the plot to file
  my_dist_list[[d]] = dist_MDS
}

# plot an overview of MDS with different distance metric
for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  a <- get(var)
  my_df = ldply(my_dist_list, function(x) x$data)
  names(my_df)[1] <- "distance"
  # check if variable is continuous or distinct
  if (class(my_df[[a]]) == "integer") {
    dist_MDS = ggplot(my_df, aes_string("Axis.1", "Axis.2", color=a)) +
      geom_point(size=2, alpha=0.7) +
      facet_wrap(~distance, scales="free") +
      ggtitle("MDS on various distance metrics")
    print(dist_MDS)
  }
  else 
    # use color palette Set2 if variable is discrete
    dist_MDS = ggplot(my_df, aes_string("Axis.1", "Axis.2", color=a)) +
    geom_point(size=2, alpha=0.7) +
    scale_fill_brewer(type="qual", palette="Set2") +
    scale_colour_brewer(type="qual", palette="Set2") +
    facet_wrap(~distance, scales="free") +
    ggtitle("MDS on various distance metrics")
  print(dist_MDS)
  file_name = paste("05_my_dist_MDS_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(dist_MDS, width=unit(1.5, "in"), height=unit(1.5, "in")), file = file_name, width = 15, height = 15)
}


# plot single MDS/PCoA ordinations of Bray-Curtis, Unifrac, weighted Unifrac, and Jensson-Shennon. 
# Colored according to every variable

for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  # check if variable is continuous and in that case use standard color scheme
  # Bray-Curtis metric
  if (class(my_df[[x]]) == "integer") { 
    pbray <- my_dist_list[["bray"]]
    pbray$layers <- pbray$layers[-1]
    pbray_MDS <- pbray + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x))
    file_name = paste("05_my_bray_MDS_",var, ".pdf", sep="")
    ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
    # Unifrac metric
    punifrac <- my_dist_list[["unifrac"]]
    punifrac$layers <- punifrac$layers[-1]
    punifrac_MDS <- punifrac + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x))
    file_name = paste("05_my_unifrac_MDS_",var, ".pdf", sep="")
    ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
    # weighted Unifrac metric
    pwunifrac <- my_dist_list[["wunifrac"]]
    pwunifrac$layers <- pwunifrac$layers[-1]
    pwunifrac_MDS <- pwunifrac + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x))
    file_name = paste("05_my_wunifrac_MDS_",var, ".pdf", sep="")
    ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
    # JSD metric
    pjsd <- my_dist_list[["jsd"]]
    pjsd$layers <- pjsd$layers[-1]
    pjsd_MDS <- pjsd + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x))
    file_name = paste("05_my_jsd_MDS_",var, ".pdf", sep="")
    ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
    next
  } 
  else
    # for all discrete variables do the following
    # Bray-Curtis metric
    pbray <- my_dist_list[["bray"]]
  pbray$layers <- pbray$layers[-1]
  pbray_MDS <- pbray + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x)) +  scale_fill_brewer(type="qual", palette="Set2") + scale_colour_brewer(type="qual", palette="Set2")
  file_name = paste("05_my_bray_MDS_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
  # Unifrac metric
  punifrac <- my_dist_list[["unifrac"]]
  punifrac$layers <- punifrac$layers[-1]
  punifrac_MDS <- punifrac + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x)) + scale_fill_brewer(type="qual", palette="Set2") + scale_colour_brewer(type="qual", palette="Set2")
  file_name = paste("05_my_unifrac_MDS_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
  # weighted Unifrac metric
  pwunifrac <- my_dist_list[["wunifrac"]]
  pwunifrac$layers <- pwunifrac$layers[-1]
  pwunifrac_MDS <- pwunifrac + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x)) + scale_fill_brewer(type="qual", palette="Set2") + scale_colour_brewer(type="qual", palette="Set2")
  file_name = paste("05_my_wunifrac_MDS_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
  # JSD metric
  pjsd <- my_dist_list[["jsd"]]
  pjsd$layers <- pjsd$layers[-1]
  pjsd_MDS <- pjsd + geom_point(aes_string("Axis.1", "Axis.2", color=x), size=3.5, alpha = 0.7) + guides(color=guide_legend(title=x)) + scale_fill_brewer(type="qual", palette="Set2") + scale_colour_brewer(type="qual", palette="Set2")
  file_name = paste("05_my_jsd_MDS_",var, ".pdf", sep="")
  ggsave(egg::set_panel_size(pbray_MDS, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
}



# NMDS of Bray-Curtis, Unifrac, weighted Unifrac, and Jensson-Shennon. Colored according to every variable

for ( dist in c("bray","jsd", "unifrac", "wunifrac")) {
  ord_meths = c("CCA", "DCA", "RDA", "NMDS", "MDS") # call different ordination methods
  # excluded "DPCoA"
  # excluded PCoA because it is identical to MDS
  #ord_meths = c("NMDS") # call different ordination methods
  
  for ( n in 1:(i-2) ) {
    var <- paste("var", n, sep="")
    x <- get(var)
    plist = llply(as.list(ord_meths), function(y, my_physeq_filt_rel, dist){
      set.seed(2)
      ordi = ordinate(my_physeq_filt_rel, method=y, distance=dist)
      plot_ordination(my_physeq_filt_rel, ordi, "samples", color=x)
    }, my_physeq_filt_rel, dist)
    names(plist) <- ord_meths
    
    # extract the data from each of those individual plots, and put it back together in one big data.frame
    pdataframe = ldply(plist, function(y){
      df = y$data[, 1:2]
      colnames(df) = c("Axis_1", "Axis_2")
      return(cbind(df, y$data))
    })
    names(pdataframe)[1] = "method"
    
    # Now that all the ordination results are combined in one data.frame, called pdataframe - make a standard faceted scatterplot.
    if (class(pdataframe[[x]]) == "integer") {
      my_ord_combo = ggplot(pdataframe, aes_string("Axis_1", "Axis_2", color=x, fill=x), alpha = 0.7) +
        geom_point(size=3, alpha = 0.7) + #geom_polygon(alpha=0.5) +
        facet_wrap(~method, scales="free")
      print(my_ord_combo) + ggtitle(print(dist))
    }
    else
      my_ord_combo = ggplot(pdataframe, aes_string("Axis_1", "Axis_2", color=x, fill=x), alpha = 0.7) +
      geom_point(size=3, alpha = 0.7) + #geom_polygon(alpha=0.5) +
      facet_wrap(~method, scales="free") +
      scale_fill_brewer(type="qual", palette="Set2") +
      scale_colour_brewer(type="qual", palette="Set2")
    my_ord_combo_plot <- print(my_ord_combo + ggtitle(print(dist)))
    
    file_name = paste("05_my_",dist , "_ordinOverview_", var, ".pdf", sep="")
    ggsave(my_ord_combo_plot, file = file_name, width = 10, height = 7)
  }
}


my_single_comb_NMDS_list <- NULL
for( dist in c("bray","jsd", "unifrac", "wunifrac") ){
  set.seed(2)
  my_single_NMDS <- NULL
  my_single_comb_NMDS <- ordinate(my_physeq_filt_rel, method="NMDS", distance=dist)
  if (my_single_comb_NMDS$stress >= 0.20) {
    stresslevel <- paste("WARNING: stress", round(my_single_comb_NMDS$stress,4), "is > 0.20 - representation may be random!", sep = " ")
  } else {
    stresslevel <- paste("Stress",round(my_single_comb_NMDS$stress,4),sep=" ")
  }
  my_single_comb_NMDS_plot <- plot_ordination(my_physeq_filt_rel, my_single_comb_NMDS, "samples") + ggtitle(paste("NDMS on",dist, sep=" ")) + labs(caption = paste(stresslevel))
  my_single_comb_NMDS_plot$layers <- my_single_comb_NMDS_plot$layers[-1]  # remove first layer
  my_single_comb_NMDS_list[[dist]] = my_single_comb_NMDS_plot
}

for ( n in 1:(i-2) ) {
  var <- paste("var", n, sep="")
  x <- get(var)
  for( dist in c("bray","jsd", "unifrac", "wunifrac") ){
    if (class(pdataframe[[x]]) == "integer") {
      pdist <- my_single_comb_NMDS_list[[dist]] + 
        geom_point(aes_string(color=x), size=3.5, alpha=0.7) +
        guides(col=guide_legend(x))
    } else {
      pdist <- my_single_comb_NMDS_list[[dist]] + 
        geom_point(aes_string(color=x), size=3.5, alpha=0.7) +
        scale_colour_brewer(type="qual", palette="Set2") +
        scale_fill_brewer(type="qual", palette="Set2") +
        guides(col=guide_legend(x))
    }
    file_name = paste("05_my_",dist , "_NMDS_", var, ".pdf", sep="")
    ggsave(egg::set_panel_size(pdist, width=unit(6, "in"), height=unit(6, "in")), file = file_name, width = 8, height = 7)
  }
}

########################
