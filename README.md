# ASV_annotation
ASV fasta to correct lineage annotation for FUNGuild


# Introduction
Assume you get a fasta file with ASV's or OTU's, but you need to get the information in a shape for FUNGuild
This run through assumes you have ITS data. Supplement the `wget` command for NCBI with the appropriate database you need.

## Getting the databases
```wget https://ftp.ncbi.nlm.nih.gov/blast/db/ITS_eukaryote_sequences.tar.gz``` for the ITS database

```wget https://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz``` for the taxonomic information

## Preparing the taxonomy file
[ncbitax2lin](https://github.com/zyxue/ncbitax2lin) was great for this, and gave me this output:
```
tax_id,domain,phylum,class,order,family,genus,species,acellular root,biotype,cellular root,clade,clade1,clade10,clade11,clade12,clade13,clade14,clade15,clade16,clade17,clade18,clade19,clade2,clade20,clade21,clade22,clade3,clade4,clade5,clade6,clade7,clade8,clade9,cohort,forma,forma specialis,forma specialis1,genotype,infraclass,infraorder,isolate,kingdom,morph,no rank,no rank1,no rank2,no rank3,no rank4,parvorder,pathogroup,realm,section,series,serogroup,serotype,species group,species subgroup,strain,subclass,subcohort,subfamily,subgenus,subkingdom,suborder,subphylum,subsection,subspecies,subtribe,subvariety,superclass,superfamily,superorder,superphylum,tribe,varietas
1,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,root,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
2,Bacteria,,,,,,,,,cellular organisms,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
6,Bacteria,Pseudomonadota,Alphaproteobacteria,Hyphomicrobiales,Xanthobacteraceae,Azorhizobium,,,,cellular organisms,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,Pseudomonadati,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
7,Bacteria,Pseudomonadota,Alphaproteobacteria,Hyphomicrobiales,Xanthobacteraceae,Azorhizobium,Azorhizobium caulinodans,,,cellular organisms,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,Pseudomonadati,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
9,Bacteria,Pseudomonadota,Gammaproteobacteria,Enterobacterales,Erwiniaceae,Buchnera,Buchnera aphidicola,,,cellular organisms,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,Pseudomonadati,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
```
But I needed something a bit different

On the CSV produced by ncbitax2lin, I ran [tidy_taxonomy.sh](https://github.com/lpotgieter/ASV_annotation/blob/main/tidy_taxonomy.sh) to create an output that is starting to take shape

```
tax_id;k__domain;p__phylum;c__class;o__order;f__family;g__genus;s__species
1
2;k__Bacteria
6;k__Bacteria;p__Pseudomonadota;c__Alphaproteobacteria;o__Hyphomicrobiales;f__Xanthobacteraceae;g__Azorhizobium
7;k__Bacteria;p__Pseudomonadota;c__Alphaproteobacteria;o__Hyphomicrobiales;f__Xanthobacteraceae;g__Azorhizobium;s__Azorhizobium
9;k__Bacteria;p__Pseudomonadota;c__Gammaproteobacteria;o__Enterobacterales;f__Erwiniaceae;g__Buchnera;s__Buchnera
```
and a tabbed output where the taxID is separated from the taxonomy info by a tab.

## BLAST
```
blastn -db ITS_eukaryote_sequences -query feature.fasta -max_target_seqs 1 -outfmt "6 qseqid sseqid staxids pident length mismatch gapopen qstart qend sstart send evalue bitscore sblastnames sscinames" > blast_out
```
To give me an output like this
```
ASV0    gb|MH711573.1|  312789  98.383  371     6       0       1       371     286     656     0.0     652     eudicots        Betula luminifera
ASV1    gb|MH711573.1|  312789  98.113  371     7       0       1       371     286     656     0.0     647     eudicots        Betula luminifera
```

```
awk -F'\t' -v OFS='\t' 'NR==FNR {map[$1]=$2; next} {print $0, ( $3 in map ? map[$3] : "NA" )}' tidied_tab blast_out > combined_tax_blast
```
so that the `combined_tax_blast` looks like this

```
ASV0    gb|MH711573.1|  312789  98.383  371     6       0       1       371     286     656     0.0     652     eudicots        Betula luminifera  k__Eukaryota;p__Streptophyta;c__Magnoliopsida;o__Fagales;f__Betulaceae;g__Betula;s__Betula
ASV1    gb|MH711573.1|  312789  98.113  371     7       0       1       371     286     656     0.0     647     eudicots        Betula luminifera  k__Eukaryota;p__Streptophyta;c__Magnoliopsida;o__Fagales;f__Betulaceae;g__Betula;s__Betula
```
We are making progress!
FUNGuild wants something like this
```
OTU ID	sample1	sample2	sample3	sample4	sample5	taxonomy
OTU_100	0	1	0	0	0	93.6%|Laetisaria_fuciformis|EU118639|SH012042.06FU|reps_singleton|k__Fungi;p__Basidiomycota;c__Agaricomycetes;o__Corticiales;f__Corticiaceae;g__Laetisaria;s__Laetisaria_fuciformis
```
so we need to drop a bunch of info from our BLAST result (rather have too much than too little if you need to go back and check whether you are confident in what you've found!) and shuffle things around a bit.

To add a % to the identity column
```
awk -F'\t' -v OFS='\t' '{ $4 = $4 "%" }1' combined_tax_blast > tmp && mv tmp combined_tax_blast
```

Here we combine to have the ASV in the first column, and combine the percentage identity, the scientific name, and the lineage column into one
```
awk -F'\t' -v OFS='\t' '{  gsub(/ /, "_", $15);  print $1, $4 "|" $15 "|" $16}' combined_tax_blast > combined_merged
```
So that it looks like this
```
ASV0    98.383%|Betula_luminifera|k__Eukaryota;p__Streptophyta;c__Magnoliopsida;o__Fagales;f__Betulaceae;g__Betula;s__Betula
ASV1    98.113%|Betula_luminifera|k__Eukaryota;p__Streptophyta;c__Magnoliopsida;o__Fagales;f__Betulaceae;g__Betula;s__Betula
```

To combined this with your feature table
```
awk -F'\t' -v OFS='\t' 'NR==FNR { map[$1]=$2; next } { print $0, ( $1 in map ? map[$1] : "NA" ) }' combined_merged feature_table.txt > combined_feature_table.txt
```
