#!/bin/bash

# Retrieve absolute path to this script
script=$(readlink -f "$0")
scriptpath=$(dirname "$script")

# Parse arguments from flags
target_file=""
output_file="john.txt"
while getopts f:o: flag; do
    case "${flag}" in
        f) target_file=${OPTARG};;
        o) output_file=${OPTARG};;
    esac
done

# Directories containing wordlist files
directories=(
    "/usr/share/seclists/Passwords"
)

# Ensure the output file is empty before starting
> "$output_file"

# Check if target file is provided
if [[ -z "$target_file" ]]; then
    echo "Error: Target file (-f) not specified."
    exit 1
fi

# Process directories recursively
for dir in "${directories[@]}"; do
    echo "Processing directory: $dir"

    # Use find to retrieve all files in the directory tree
    find "$dir" -type f | while read -r wordlist; do
        echo "Using wordlist: $wordlist"
        john --wordlist="$wordlist" --rules "$target_file" >> "$output_file"
    done
done

echo "Consolidated results saved in: $output_file"

