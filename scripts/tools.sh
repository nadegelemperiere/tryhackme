#! /bin/bash

# ----------------------
# System Setup
# ----------------------
apt update

# Install Docker for containerization
apt install -y docker.io
systemctl enable docker --now

# Install essential tools
apt install -y file jq p7zip-full parallel openjdk-23-jdk

# ----------------------
# Exploitation Frameworks
# ----------------------

# Install Metasploit
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
chmod 755 msfinstall
./msfinstall

# ----------------------
# Vulnerability Scanning and Network Analysis
# ----------------------

# Install networking tools and vulnerability scanners
apt install -y kali-linux-default webshells
apt install -y nmap sqlmap enum4linux-ng
apt install -y wireshark tshark burpsuite zaproxy
apt install -y socat rlwrap


# ----------------------
# Web and Application Analysis
# ----------------------

# Browsers
apt install -y firefox-esr

# Puppeteer for web automation and SPA analysis
apt install -y npm
npm install playwright
npx playwright install

# Fuzzing tools
apt install -y ffuf gobuster wfuzz

# Steganography and cryptography tools
apt install -y libimage-exiftool-perl binwalk ghidra
wget https://github.com/syvaidya/openstego/releases/download/openstego-0.8.6/openstego-0.8.6.zip
unzip openstego-0.8.6.zip -d /usr/local/bin
mv /usr/local/bin/openstego-0.8.6 /usr/local/bin/openstego
chmod +x /usr/local/bin/openstego/openstego.sh
apt install -y steghide

# ----------------------
# Credential and Authentication Testing
# ----------------------

# Password cracking tools
apt install -y hydra john hashcat

# Username enumeration and TOTP generation
apt install -y sherlock oathtool

# Password manager
apt install -y keepassxc-full

# SSH automation
apt install -y sshpass

# Privilege escalation enumeration
curl -X GET https://github.com/rebootuser/LinEnum/blob/master/LinEnum.sh -o /usr/bin/LinEnum.sh
chmod +x /usr/bin/LinEnum.sh

# ----------------------
# Mobile and Application Analysis
# ----------------------

# Install Frida for dynamic instrumentation
pip install --break-system-packages frida-tools
