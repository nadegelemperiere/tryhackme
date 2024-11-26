#!/bin/bash

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Parse arguments from flags
target_url=""
target_port="80"
output_file="gobuster.txt"
while getopts u:o:p: flag
do
    case "${flag}" in
        u) target_url=${OPTARG};;
        p) target_port=${OPTARG};;
        o) output_file=${OPTARG}
    esac
done

# Directories containing wordlist files
directories=(
    "/usr/share/wordlists/dirb"
    "/usr/share/wordlists/dirbuster"
)

# Gobuster options
gobuster_options="--quiet --follow-redirect -w {WORDLIST} -u http://$target_url:$target_port -t 20 -o temp_result.txt"


# Temporary file for intermediate results
temp_file="temp_results_all.txt"

# Ensure the output file is empty before starting
> "$output_file"
> "$temp_file"

# Loop over directories
for dir in "${directories[@]}"; do
    echo "Processing directory: $dir"
    # Loop over wordlist files in each directory
    for wordlist in "$dir"/*.txt; do
        if [[ -f "$wordlist" ]]; then
            echo "Using wordlist: $wordlist"
            # Replace {WORDLIST} in gobuster options with the current wordlist
            options=$(echo "$gobuster_options" | sed "s|{WORDLIST}|$wordlist|")
            
            # Run gobuster and append results to the temp file
            gobuster dir $options 2>/dev/null
            if [[ -f "temp_result.txt" ]]; then
                cat temp_result.txt >> "$temp_file"
                rm temp_result.txt
            fi
        fi
    done
done

# Remove duplicates and write to the final output file
sort -u "$temp_file" > "$output_file"
rm "$temp_file"

echo "Consolidated results saved in: $output_file"
