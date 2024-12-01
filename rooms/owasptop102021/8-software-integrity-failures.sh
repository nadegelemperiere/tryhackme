#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.195.209"
attack_ip="10.10.113.137"

# Prepare environment
mkdir /work/ 2>/dev/null

# Collect database content from assets directory (look at the page source code)
echo "1 - RETRIEVING SCRIPT"
wget -q https://code.jquery.com/jquery-1.12.4.min.js
mv jquery-1.12.4.min.js /work/8-jquery-1.12.4.min.js

# Computing hash
echo "2 - COMPUTING HASH"
openssl dgst -sha256 -binary /work/8-jquery-1.12.4.min.js | base64 | awk '{print "sha256-"$1}'