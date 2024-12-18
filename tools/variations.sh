#!/bin/bash

# Retrieve absolute path to this script
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")

# Parse arguments from flags
words=()
output_file="variations.txt"
while getopts w:o: flag; do
    case "${flag}" in
        o) output_file=${OPTARG} ;;
        w) words+=("${OPTARG}") ;;  # Properly append word preserving spaces
    esac
done

# Function to generate case variations
generate_case_variations() {
    local word="$1"
    perl -le '$_=shift; for $i (0..(2**length($_)-1)) { $new=$_; $new=~s/(.)/($i>>$-[0]&1)?uc($1):lc($1)/ge; print $new }' "$word"

}

# Function to apply leetspeak transformations
apply_leetspeak() {
    local word="$1"
    echo "$word" | sed '
        s/[a]/4/g;
        s/[e]/3/g;
        s/[i]/1/g;
        s/[o]/0/g;
        s/[s]/5/g;
        s/[l]/1/g;
        s/[t]/7/g
    '
}

# Generate all variations
echo "Generating variations for: ${words[*]}"
> "$output_file"  # Clear or create the output file

for word in "${words[@]}"; do
    # Generate case variations
    case_variations=$(generate_case_variations "$word")
    
    # Apply leetspeak to each case variation
    while IFS= read -r case_variation; do
        echo "$case_variation" >> "$output_file"  # Original case variation
        leet_variation=$(apply_leetspeak "$case_variation")
        echo "$leet_variation" >> "$output_file"  # Leetspeak variation
    done <<< "$case_variations"
done

# Remove duplicates and sort
sort -u -o "$output_file" "$output_file"

echo "Variations saved to $output_file"
