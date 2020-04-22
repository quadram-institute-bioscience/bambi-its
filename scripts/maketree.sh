#!/bin/bash 
THREADS=8
TEMP=$(mktemp -u)
if [[ "$2NO" == "$2" ]]; then
 OUT="$(echo $1 | cut -f1 -d.).tre"
else
 OUT=$2
fi

if [ -e "$1" ]; then
  clustalo -i "$1" -o "$TEMP" --outfmt fa --threads=$THREADS --force
  fasttree  -nt -gtr -no2nd -spr 4 -quiet "$TEMP" > "$OUT" 
  rm "$TEMP"
  echo $OUT
else 
  echo Usage: maketree.sh "input.fasta" [output.tree]
  exit 1
fi
