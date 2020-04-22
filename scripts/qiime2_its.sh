#!/bin/bash

echo "
USAGE:
its.sh Database_Name Reads_DIR Output_DIR [ItsX]";

#wget https://unite.ut.ee/sh_files/sh_qiime_release_20.11.2016.zip
#wget https://dl.dropboxusercontent.com/u/2868868/temp/sh_refs_qiime_ver7_99_20.11.2016.fasta
#wget https://dl.dropboxusercontent.com/u/2868868/temp/sh_taxonomy_qiime_ver7_99_20.11.2016.txt
#wget https://unite.ut.ee/sh_files/sh_qiime_release_20.11.2016.zip


# Reference folder - Database
REF='../ref'
#DB="$REF/unite8-99.qza"

# Input reads
#READS='../reads'
METADATA='sample-metadata.tsv'

CORE='core'
THREADS=8
RARE=8000
DEPTH=10000

DB=$1
READS=$2
OUT=$3
ITSX=$4

if [ "NO$3" == "NO" ]; then
		echo Missing parameters
		exit 0
fi

if [ "NO$4" == "NO" ]; then
	ITSX='skip'
else
	ITSX='itsx'
fi 
set -euxo pipefail 

mkdir -p "$OUT"


 
if [ ! -e "${OUT}/reads_raw.qza" ]; then
 
  qiime tools import   --type 'SampleData[PairedEndSequencesWithQuality]'   \
    --input-path "$READS" --input-format CasavaOneEightSingleLanePerSampleDirFmt   \
    --output-path ${OUT}/reads_raw.qza
fi

if [ $ITSX == 'itsx' ]; then
	echo 'ITSxpress'
	 if [ ! -e "${OUT}/reads.qza" ]; then
		qiime itsxpress trim-pair-output-unmerged \
			--i-per-sample-sequences ${OUT}/reads_raw.qza \
			--p-region ITS1 \
			--p-taxa F \
			--p-threads $THREADS \
			--o-trimmed ${OUT}/reads.qza
	 fi
else
	echo 'Skipping'
	mv "${OUT}"/reads_raw.qza "${OUT}"/reads.qza
fi



if [ ! -e "${OUT}/reads.qzv" ]; then
  qiime demux summarize \
    --i-data "${OUT}"/reads.qza \
    --o-visualization "${OUT}"/reads.qzv

  if [ $ITSX == 'itsx' ]; then

	qiime demux summarize \
	   --i-data "${OUT}"/reads_raw.qza \
	   --o-visualization "${OUT}"/reads_raw.qzv
  fi
fi



if [ ! -d "${OUT}/dada2" ]; then
 qiime dada2 denoise-paired --i-demultiplexed-seqs  ${OUT}/reads.qza \
   --output-dir ${OUT}/dada2 \
   --p-trunc-len-f 160 --p-trunc-len-r 130 \
   --p-trim-left-f 0  --p-trim-left-r 0 \
   --p-n-threads $THREADS \
   --verbose 

fi

if [ ! -e "${OUT}/rep-seqs.qza" ]; then
    mv -v "${OUT}"/dada2/representative_sequences.qza "${OUT}"/rep-seqs.qza
    mv -v "${OUT}"/dada2/table.qza "${OUT}"/
fi

if [ ! -e "${OUT}/taxonomy.qza" ]; then
    qiime feature-classifier classify-sklearn   \
        --i-classifier ${DB} \
        --i-reads ${OUT}/rep-seqs.qza   \
        --o-classification ${OUT}/taxonomy.qza
fi
if [ ! -e "${OUT}/taxonomy.qzv" ]; then
    qiime metadata tabulate     \
      --m-input-file ${OUT}/taxonomy.qza   \
      --o-visualization ${OUT}/taxonomy.qzv

fi

if [ ! -e "${OUT}/table.qzv" ]; then
    qiime taxa barplot   \
        --i-table ${OUT}/table.qza   --i-taxonomy ${OUT}/taxonomy.qza \
        --m-metadata-file "$METADATA"   \
        --o-visualization ${OUT}/taxa-bar-plots.qzv

    qiime feature-table summarize   --i-table ${OUT}/table.qza   \
        --o-visualization ${OUT}/table.qzv   \
        --m-sample-metadata-file "$METADATA"
fi

if [ ! -e "${OUT}/table.qzv" ]; then
    qiime feature-table summarize     --i-table ${OUT}/table.qza   --o-visualization ${OUT}/table.qzv   --m-sample-metadata-file $METADATA
    qiime feature-table tabulate-seqs --i-data ${OUT}/rep-seqs.qza --o-visualization ${OUT}/rep-seqs.qzv
fi
 
if [ ! -e "${OUT}/rooted-tree.qza" ]; then
    qiime phylogeny align-to-tree-mafft-fasttree    --i-sequences ${OUT}/rep-seqs.qza   \
        --o-alignment ${OUT}/aligned-rep-seqs.qza   --o-masked-alignment ${OUT}/masked-aligned-rep-seqs.qza   \
        --o-tree ${OUT}/unrooted-tree.qza           --o-rooted-tree ${OUT}/rooted-tree.qza
fi

if [ ! -d "${OUT}/$CORE" ]; then
  qiime diversity core-metrics-phylogenetic   \
    --i-phylogeny ${OUT}/rooted-tree.qza   --i-table ${OUT}/table.qza   \
    --p-sampling-depth $RARE   --m-metadata-file $METADATA   \
    --output-dir ${OUT}/$CORE
fi

if [ ! -e "${OUT}/$CORE/BetaSig_unweighted-unifrac-treatment-significance.qzv" ]; then
    qiime diversity alpha-group-significance   \
    --i-alpha-diversity ${OUT}/$CORE/faith_pd_vector.qza   --m-metadata-file $METADATA   \
    --o-visualization ${OUT}/$CORE/AlphaSig_faith-pd_group-significance.qzv

    qiime diversity alpha-group-significance   \
        --i-alpha-diversity  ${OUT}/$CORE/evenness_vector.qza   \
        --m-metadata-file $METADATA   \
        --o-visualization  ${OUT}/$CORE/AlphaSig_evenness-group-significance.qzv

    # @COLUMN
    qiime diversity beta-group-significance  \
        --i-distance-matrix ${OUT}/$CORE/unweighted_unifrac_distance_matrix.qza   \
        --m-metadata-file $METADATA   --m-metadata-column treatment   \
        --o-visualization ${OUT}/$CORE/BetaSig_unweighted-unifrac-treatment-significance.qzv   --p-pairwise

fi


ls "${OUT}/rarefaction.qzv" || qiime diversity alpha-rarefaction   --i-table ${OUT}/table.qza   \
    --i-phylogeny ${OUT}/rooted-tree.qza   --p-max-depth $DEPTH   --m-metadata-file $METADATA --o-visualization ${OUT}/rarefaction.qzv

ls "${OUT}/taxa-bar-plots.qzv" || qiime taxa barplot   --i-table ${OUT}/table.qza   --i-taxonomy ${OUT}/taxonomy.qza   \
    --m-metadata-file $METADATA   --o-visualization ${OUT}/taxa-bar-plots.qzv

ls "${OUT}/taxonomy.qza" || qiime feature-classifier classify-sklearn   --i-classifier ${REF}/unite-ver7-99-classifier-20.11.2016.qza   \
    --i-reads ${OUT}/rep-seqs.qza   --o-classification ${OUT}/taxonomy.qza

ls "${OUT}/taxa-bar-plots.qzv" || qiime taxa barplot   --i-table ${OUT}/table.qza   --i-taxonomy ${OUT}/taxonomy.qza   \
    --m-metadata-file $METADATA   --o-visualization ${OUT}/taxa-bar-plots.qzv


if [ ! -e "${OUT}/ancom.done" ]; then
qiime composition add-pseudocount  \
   --i-table ${OUT}/table.qza   \
   --o-composition-table ${OUT}/table-counts.qza

qiime composition ancom   --i-table ${OUT}/table-counts.qza   --m-metadata-file $METADATA   \
  --m-metadata-column treatment   --o-visualization ${OUT}/ancom-treatment.qzv

qiime composition ancom   --i-table ${OUT}/table-counts.qza   --m-metadata-file $METADATA   \
  --m-metadata-column sex   --o-visualization ${OUT}/ancom-sex.qzv

  qiime composition ancom   --i-table ${OUT}/table-counts.qza   --m-metadata-file $METADATA   \
  --m-metadata-column delivery   --o-visualization ${OUT}/ancom-delivery.qzv

  touch ${OUT}/ancom.done
fi


# qiime composition ancom   --i-table comp-gut-table.qza   --m-metadata-file $METADATA   --m-metadata-column treatment   --o-visualization ancom-months.qzv

# qiime composition ancom   --i-table comp-gut-table.qza   --m-metadata-file $METADATA   --m-metadata-column sex   --o-visualization ancom-sex.qzv

# qiime composition ancom   --i-table comp-gut-table.qza   --m-metadata-file $METADATA   --m-metadata-column delivery   --o-visualization ancom-delivery.qzv

# qiime composition ancom   --i-table comp-table.qza   --m-metadata-file $METADATA   --m-metadata-column treatment   --o-visualization ancom-months.qzv

# qiime composition ancom   --i-table comp-table.qza   --m-metadata-file $METADATA   --m-metadata-column sex   --o-visualization ancom-sex.qzv

# qiime composition ancom   --i-table comp-table.qza   --m-metadata-file $METADATA   --m-metadata-column delivery   --o-visualization ancom-delivery.qzv

# echo Import taxonomy
# if [ ! -e "${REF}/unite8-99-seqs.qza" ]; then
#  qiime tools import  --type FeatureData[Sequence]  --input-path ${REF}/sh_refs_qiime_ver8_99_02.02.2019.fasta  \
#    --output-path ${REF}/unite8-99-seqs.qza
# fi

# if [ ! -e "$REF/unite8-99-tax.qza" ]; then
#  #qiime tools import  --type FeatureData[Taxonomy]  --input-path ${REF}/sh_taxonomy_qiime_ver8_99_02.02.2019.txt --output-path ${REF}/unite-ver7-99-tax-20.11.2016.qza  --source-format HeaderlessTSVTaxonomyFormat
#  qiime tools import  --type FeatureData[Taxonomy]  --input-path ${REF}/sh_taxonomy_qiime_ver8_99_02.02.2019.txt \
#    --output-path ${REF}/unite8-99-tax.qza  \
#    --input-format HeaderlessTSVTaxonomyFormat

# fi

# if [ ! -e "$REF/unite8-99.qza" ]; then
#   qiime feature-classifier fit-classifier-naive-bayes  \
#      --i-reference-reads ${REF}/unite8-99-seqs.qza  \
#      --i-reference-taxonomy ${REF}/unite8-99-tax.qza   \
#      --o-classifier ${REF}/unite8-99.qza
# fi



