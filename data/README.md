* **metadata.tsv** - Project metadata

* **asv.fa** - Amplicon Sequence Variants (ASVs) identified using the [USEARCH protocol](https://github.com/quadram-institute-bioscience/bambi-its/wiki/USEARCH).
 
* **asv.tre** - Distance tree in newick format of the ASV identified

* **taxonomy.?sv** - Tabular file containing the taxonomical classification of each ASV identified.

* **feature-table** - Directory containing intermediate files to produce the final _feature table_.

    * *raw_table_asv.tsv* - raw counts performed by _usearch -otutab_
    * *table_uncrossed.tsv* - cross talk removal by *usearch -otutab_xtalk*
    * *table_freq.tsv* - relative counts (frequencies), 
    * *table_uncross_filtered.tsv* - removed samples with <8000 hits, and ASV with <0.1% size. Lost 1 / 30 samples, and 214 / 272 ASVs


* **feature-table.tsv** - OTU Table in TSV format (equal to *table_uncrossed.tsv*)

