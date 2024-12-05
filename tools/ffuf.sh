#!/bin/bash

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Parse arguments from flags
target_url=""
output_file="ffuf.txt"
additional_options=""
pattern="*.txt"
threads=10
while getopts u:o:p:a:m:t: flag
do
    case "${flag}" in
        u) target_url=${OPTARG};;
        o) output_file=${OPTARG};;
        a) additional_options=${OPTARG};;
        m) pattern=${OPTARG};;
        t) threads=${OPTARG}
    esac
done

# Directories containing wordlist files
directories=(
    "/usr/share/seclists/Discovery/Web-Content/"
)

# Gobuster options
ffuf_options="-w {WORDLIST} -u http://$target_url/FUZZ -t $threads $additional_options -o temp_result.txt"


# Temporary file for intermediate results
temp_file="temp_results_all.txt"

# Ensure the output file is empty before starting
> "$output_file"
> "$temp_file"

# Loop over directories
for dir in "${directories[@]}"; do
    echo "Processing directory: $dir"
    # Loop over wordlist files in each directory
    for wordlist in "$dir"/$pattern; do
        if [[ -f "$wordlist" ]]; then
            echo "Using wordlist: $wordlist"
            # Replace {WORDLIST} in gobuster options with the current wordlist
            options=$(echo "$ffuf_options" | sed "s|{WORDLIST}|$wordlist|")
            
            # Run gobuster and append results to the temp file
            ffuf $options
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
