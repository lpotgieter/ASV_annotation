#!/bin/bash

# Input CSV file
INPUT="ncbi_lineages_2025-05-23.csv"
WORKFILE="work"
OUTPUT="tidied_taxonomy"

awk '{print $1}' "$INPUT" > "$WORKFILE"
sed -i 's/,/;k__/1' "$WORKFILE"
sed -i 's/,/;p__/1' "$WORKFILE"
sed -i 's/,/;c__/1' "$WORKFILE"
sed -i 's/,/;o__/1' "$WORKFILE"
sed -i 's/,/;f__/1' "$WORKFILE"
sed -i 's/,/;g__/1' "$WORKFILE"
sed -i 's/,/;s__/1' "$WORKFILE"
sed -i 's/,.*//' "$WORKFILE"
sed 's/\(;[a-z]__\)\(;.*\)*$//' "$WORKFILE" > "$OUTPUT"
sed 's/;k/\tk/g' "$OUTPUT" > "$OUTPUT"_tab
