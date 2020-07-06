#!/bin/bash

echo " USAGE:
$(basename $0) [options] -r repseqs -t table -d database -o output_dir
 
  -r REPSEQ    rep-seq.qza artifact (ASVs)
  -t TABLE     feature table artifact
  -d DATABASE  Reference database (UNITE)
  -o OUTDIR    Output directory
  -c CORES     Processing cores
  -j CATEGORY  Metadata column for analysis
  -v           Verbose
";

qiime 2>/dev/null || { echo "Activate qiime to use this script"; exit 1; }


 
# DEFAULTS
METADATA='sample-metadata.tsv'
opt_otutab='table.qza'
opt_repseqs='rep-seqs.qza'
opt_outdir='qiime2_analysis'

treatment='treatment'
CORE='core'
THREADS=8
RARE=8000
DEPTH=10000

while getopts t:r:o:d:m:c:j:v option
do
  case "${option}"
    in
      t) opt_otutab=${OPTARG};;
      r) opt_repseqs=${OPTARG};;
      o) opt_outdir=${OPTARG};;
      d) DB=${OPTARG};;
      m) METADATA=${OPTARG};;
      v) set -x pipefail;;
      c) THREADS=${OPTARG};;
      j) treatment=${OPTARG};;
      x) ITSX=1;;
      ?) echo " Wrong parameter $OPTARG";;
  esac
done
shift "$(($OPTIND -1))"
 

mkdir -p "$opt_outdir"



if [ ! -e "${OUT}/taxonomy.qza" ]; then
    qiime feature-classifier classify-sklearn   \
        --i-classifier ${DB} \
        --i-reads ${opt_repseqs}   \
        --o-classification ${OUT}/taxonomy.qza
fi
if [ ! -e "${OUT}/taxonomy.qzv" ]; then
    qiime metadata tabulate     \
      --m-input-file ${OUT}/taxonomy.qza   \
      --o-visualization ${OUT}/taxonomy.qzv

fi

if [ ! -e "${OUT}/taxa-bar-plots.qzv" ]; then
    qiime taxa barplot   \
        --i-table ${opt_table} \
        --i-taxonomy ${OUT}/taxonomy.qza \
        --m-metadata-file "$METADATA"   \
        --o-visualization ${OUT}/taxa-bar-plots.qzv

    qiime feature-table summarize   --i-table ${opt_table}   \
        --o-visualization ${OUT}/table.qzv   \
        --m-sample-metadata-file "$METADATA"
fi

if [ ! -e "${OUT}/table.qzv" ]; then
    qiime feature-table summarize   \
      --i-table ${opt_table}   \
      --o-visualization ${OUT}/table.qzv   \
      --m-sample-metadata-file $METADATA

    qiime feature-table tabulate-seqs \
      --i-data ${opt_repseqs} \
      --o-visualization ${OUT}/rep-seqs.qzv
fi
 
if [ ! -e "${OUT}/rooted-tree.qza" ]; then
    qiime phylogeny align-to-tree-mafft-fasttree    \
        --i-sequences ${opt_repseqs}   \
        --o-alignment ${OUT}/aligned-rep-seqs.qza   \
        --o-masked-alignment ${OUT}/masked-aligned-rep-seqs.qza   \
        --o-tree ${OUT}/unrooted-tree.qza           \
        --o-rooted-tree ${OUT}/rooted-tree.qza
fi

if [ ! -d "${OUT}/$CORE" ]; then
  qiime diversity core-metrics-phylogenetic   \
    --i-phylogeny ${OUT}/rooted-tree.qza   \
    --i-table ${opt_table}   \
    --p-sampling-depth $RARE   \
    --m-metadata-file $METADATA   \
    --output-dir ${OUT}/$CORE
fi

if [ ! -e "${OUT}/$CORE/BetaSig_unweighted-unifrac-treatment-significance.qzv" ]; then
    qiime diversity alpha-group-significance   \
    --i-alpha-diversity ${OUT}/$CORE/faith_pd_vector.qza   \
    --m-metadata-file $METADATA   \
    --o-visualization ${OUT}/$CORE/AlphaSig_faith-pd_group-significance.qzv

    qiime diversity alpha-group-significance   \
        --i-alpha-diversity  ${OUT}/$CORE/evenness_vector.qza   \
        --m-metadata-file $METADATA   \
        --o-visualization  ${OUT}/$CORE/AlphaSig_evenness-group-significance.qzv

    # @COLUMN
    qiime diversity beta-group-significance  \
        --i-distance-matrix ${OUT}/$CORE/unweighted_unifrac_distance_matrix.qza   \
        --m-metadata-file $METADATA   \
        --m-metadata-column $treatment   \
        --o-visualization ${OUT}/$CORE/BetaSig_unweighted-unifrac-treatment-significance.qzv   --p-pairwise

fi


ls "${OUT}/rarefaction.qzv" || qiime diversity alpha-rarefaction   --i-table ${opt_table}   \
    --i-phylogeny ${OUT}/rooted-tree.qza   \
    --p-max-depth $DEPTH   \
    --m-metadata-file $METADATA \
    --o-visualization ${OUT}/rarefaction.qzv

ls "${OUT}/taxa-bar-plots.qzv" || qiime taxa barplot   \
    --i-table ${opt_table}   \
    --i-taxonomy ${OUT}/taxonomy.qza   \
    --m-metadata-file $METADATA   \
    --o-visualization ${OUT}/taxa-bar-plots.qzv

ls "${OUT}/taxonomy.qza" || qiime feature-classifier classify-sklearn   \
    --i-classifier ${REF}/unite-ver7-99-classifier-20.11.2016.qza   \
    --i-reads ${opt_repseqs}   \
    --o-classification ${OUT}/taxonomy.qza

ls "${OUT}/taxa-bar-plots.qzv" || qiime taxa barplot   \
    --i-table ${opt_table}   \
    --i-taxonomy ${OUT}/taxonomy.qza   \
    --m-metadata-file $METADATA   \
    --o-visualization ${OUT}/taxa-bar-plots.qzv


if [ ! -e "${OUT}/ancom.done" ]; then
  qiime composition add-pseudocount  \
     --i-table ${opt_table}   \
     --o-composition-table ${OUT}/table-counts.qza

  qiime composition ancom   \
    --i-table ${OUT}/table-counts.qza   \
    --m-metadata-file $METADATA   \
    --m-metadata-column $treatment   \
    --o-visualization ${OUT}/ancom-$treatment.qzv

# qiime composition ancom   \
#   --i-table ${OUT}/table-counts.qza   \
#   --m-metadata-file $METADATA   \
#   --m-metadata-column sex   \
#   --o-visualization ${OUT}/ancom-sex.qzv

#   qiime composition ancom   --i-table ${OUT}/table-counts.qza   --m-metadata-file $METADATA   \
#   --m-metadata-column delivery   --o-visualization ${OUT}/ancom-delivery.qzv

  touch ${OUT}/ancom.done
fi


#REF:
#wget https://unite.ut.ee/sh_files/sh_qiime_release_20.11.2016.zip
#wget https://dl.dropboxusercontent.com/u/2868868/temp/sh_refs_qiime_ver7_99_20.11.2016.fasta
#wget https://dl.dropboxusercontent.com/u/2868868/temp/sh_taxonomy_qiime_ver7_99_20.11.2016.txt
#wget https://unite.ut.ee/sh_files/sh_qiime_release_20.11.2016.zip

  


