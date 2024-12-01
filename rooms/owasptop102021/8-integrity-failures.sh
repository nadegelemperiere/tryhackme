#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.76.228"
attack_ip="10.10.239.245"

# Prepare environment
mkdir /work/ 2>/dev/null


echo "--- SOFTWARE INTEGRITY FAILURE ---"

# Retrieving script file
echo "1.1 - RETRIEVING SCRIPT"
wget -q https://code.jquery.com/jquery-1.12.4.min.js
mv jquery-1.12.4.min.js /work/8-jquery-1.12.4.min.js

# Computing hash
echo "1.2 - COMPUTING HASH"
openssl dgst -sha256 -binary /work/8-jquery-1.12.4.min.js | base64 | awk '{print "sha256-"$1}'

echo "--- DATA INTEGRITY FAILURE ---"

# Initiate session
echo "2.1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:8089" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/8-cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Computing hash
echo "2.2 - LOGIN AS GUEST AND GET TOKEN"
curl -s -X POST "http://$target_ip:8089/login" -c "/work/8-cookies.txt" -L -H "Content-Type: application/x-www-form-urlencoded" -d "user=guest" -d"pass=guest"
auth_token=$(cat /work/8-cookies.txt | grep -oP 'X-Auth-Token: \K\S+')
echo $auth_token





