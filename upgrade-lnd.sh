#!/bin/bash
clear

# initial setup
G='\033[0;32m' 		# green color
NOCOLOR='\033[0m' 	# no color

# define url strings and get new version info
echo "Getting new version info."
githubUrl="https://github.com"
newPath=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "lnd-linux-amd64" | grep -Po "href=\"\K.*\.gz")
newFile=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "lnd-linux-amd64" | grep -Po "href=\".*beta/\K.*\.gz")
newFolder=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "lnd-linux-amd64" | grep -Po "href=\".*beta/\K.*beta")
folderWStar="${newFolder}"'/*'
newFullUrl=$githubUrl$newPath
echo -e "${G}Done${NOCOLOR}"

# Stop the LND service
echo "Stopping the LND service."
sudo systemctl stop lnd
echo -e "${G}Done${NOCOLOR}"

# Change to temp directory
cd /tmp

# Download then unpack tarball
echo "Downloading and extracting tarball."
rm -rf $newFolder 
rm -rf $newFile
wget -q $newFullUrl
tar -xzf $newFile
echo -e "${G}Done${NOCOLOR}"

# Install new LND version
sudo install -m 0755 -o root -g root -t /usr/local/bin $folderWStar

# Restart LND service
echo "Starting the LND service."
sudo systemctl start lnd
echo -e "${G}Done${NOCOLOR}"
