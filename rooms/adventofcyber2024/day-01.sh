#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.221.125"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/ 2>/dev/null

# Retrieving conversion result
echo "1 - RETRIEVING CONVERTED FILES"
curl -s -X GET "http://$target_ip/download" -L -o /work/01-download.zip > /dev/null


# Analyze files
echo "2 - ANALYZING FILES"
mkdir /work/01-download
unzip -o /work/01-download.zip -d /work/01-download/
echo "--> song.mp3 : $(file /work/01-download/song.mp3)"
echo "--> somg.mp3 : $(file /work/01-download/somg.mp3)"
exiftool /work/01-download/somg.mp3 > /work/10-somg.txt
exiftool /work/01-download/song.mp3 > /work/10-song.txt

# Gather malware code
echo "3 - COLLECTING MALWARE CODE"
curl -s -X GET "https://raw.githubusercontent.com/MM-WarevilleTHM/IS/refs/heads/main/IS.ps1" -L -o /work/01-IS.ps1 > /dev/null

