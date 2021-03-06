#!/bin/bash

# This scripts process raw illumina miseq reads 
# - quality filter (fastp)
# - ASV picking (USEARCH)
# - Taxonomy annotation (USEARCH)
set -euo pipefail

SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
DIR="$SCRIPTS/../"
OUT="$DIR/usearch"
THREADS=4

usearch >/dev/null 2>&1|| { echo "'usearch' is requried in your \$PATH"; exit 1; }
fastp >/dev/null 2>&1   || { echo "'fastp' is requried in your \$PATH"; exit 1; }
mkdir -p "$OUT"
mkdir -p "reads"

echo "USAGE: $0 InputDir"

# Check required parameter (input_dir)
if [ -z ${1+x} ]; then
	echo "ERROR: Input directory required"
else
	INPUT_DIR=$1
fi 

# Check input and required files are present 

if [ ! -d "$INPUT_DIR" ]; then
	echo "ERROR: Input directory not found: $INPUT_DIR"
	exit 1
fi

if [ ! -e "$DIR/ref/utax8_04.02.2020.fa" ]; then
	echo "ERROR: Reference not found: $DIR/ref/utax8_04.02.2020.fa"
	exit 1
fi

for i in $INPUT_DIR/*R1*gz;
do
	fastp -i "$i" -I "${i/_R1/_R2}" -o reads/$(basename ${i%.gz}) -O reads/$(basename ${i/_R1/_R2} | sed 's/.gz//') \
	  --trim_front1 22 --trim_front2 20 \
	  --length_required 150 \
	  --thread $THREADS

done

if [ ! -e "$OUT/merge.fastq" ]; then
usearch -fastq_mergepairs reads/*R1* -relabel @ -fastqout $OUT/merge.fastq \
	-fastq_maxdiffs 30 -fastq_pctid 80 \
	-fastq_minmergelen 180 -threads $THREADS
fi

if [ ! -e "$OUT/filt.fa" ]; then
	usearch -fastq_filter $OUT/merge.fastq -fastaout $OUT/filt.fa \
	  -relabel filt. -fastq_maxee 0.8 -fastq_maxns 0 -threads $THREADS
fi

if [ ! -e "$OUT/uniq.fa" ]; then
	usearch -fastx_uniques $OUT/filt.fa -fastaout $OUT/uniq.fa \
  		-relabel uniq. -sizeout  -threads $THREADS
fi

if [ ! -e "$OUT/otus97.fa" ]; then
	usearch -unoise3 $OUT/uniq.fa -zotus $OUT/asv.fa
	usearch -sortbylength $OUT/asv.fa -fastaout $OUT/asv_sorted.fa -minseqlength 64
	usearch -cluster_smallmem $OUT/asv_sorted.fa -id 0.99 \
	   -centroids $OUT/otus99.fa
	usearch -cluster_smallmem $OUT/asv_sorted.fa -id 0.97 \
	   -centroids $OUT/otus97.fa
fi

for OTU_DB in $OUT/asv.fa $OUT/otus99.fa;
do
	OTU_TAG=$(basename $OTU_DB | cut -f1 -d.)
	usearch -otutab $OUT/merge.fastq -otus $OTU_DB \
	  -otutabout $OUT/otutab_$OTU_TAG.txt \
      -threads $THREADS
 
 	# For loop to allow annotation with  multiple reference (basename will be the tag)
 	for REF_DB in $DIR/ref/utax8_04.02.2020.fa;
 	do
 		REF_TAG=$(basename $REF_DB | cut -f1 -d _  | cut -f1 -d.)
 		usearch -sintax $OTU_DB -db $REF_DB -strand both -id 0.98 \
 			-tabbedout $OUT/${OTU_TAG}_${REF_TAG}.tsv -threads $THREADS
 	done
done
