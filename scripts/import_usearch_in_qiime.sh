#!/bin/bash

echo " USAGE:
$(basename $0) [options] -o output_dir
 
  -i FASTA     OTU (FASTA format)
  -t OTUTAB    OTU table in TSV format
  -o OUTDIR    Output directory
  -v           Verbose
";

qiime 2>/dev/null || { echo "Activate qiime to use this script"; exit 1; }


 
while getopts i:t:o:v option
do
        case "${option}"
                in
                        t) opt_otutab=${OPTARG};;
                        i) opt_repseqs=${OPTARG};;
						o) opt_outdir=${OPTARG};;
                        v) set -x pipefail;;
                        ?) echo " Wrong parameter $OPTARG";;
         esac
done
shift "$(($OPTIND -1))"

if [ ! -e "$opt_repseqs" ]; then
	echo "ERROR: Fasta file not found <$opt_repseqs>"
	exit 1
fi
if [ ! -e "$opt_otutab" ]; then
	echo "ERROR: Otu table file not found <$opt_otutab>"
	exit 1
fi

mkdir -p "${opt_outdir}"

biom convert --to-json -i "$opt_otutab" -o "$opt_outdir"/otutable.biom

qiime tools import \
  --input-path "$opt_repseqs" \
  --output-path "$opt_outdir"/rep-seqs.qza \
  --type 'FeatureData[Sequence]'

qiime tools import \
  --input-path "$opt_outdir"/otutable.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path "$opt_outdir"/table.qza

  