#!/bin/bash
clear


# color code setup
G='\033[0;32m' 		# green color
Y='\033[1;33m' 		# yellow color
R='\033[0;31m' 		# red color
C='\033[1;36m' 		# cyan color
NOCOLOR='\033[0m' 	# no color
cd /tmp


# parameter setup
while getopts f option
do 
    case "${option}"
        in
        f)force=0;;
		?)print_help;;
    esac
done
if ! [ -z "$force" ]; then
	echo -e "Force flag was provided"
fi


# get version information
echo -e "Getting current and new version info."
currentVersion=$(lnd --version | grep -Po "commit=\K.*$")
newVersion=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "lnd-linux-amd64" | grep -Po "download/\K.*/" | tr -d '/')
rootDl="https://github.com/lightningnetwork/lnd/releases/download/"
# will download only if new version available or if force (-f) flag was provided
if [ "$currentVersion" == "$newVersion" ] && [ -z "$force" ]; then
	echo -e "${G}Already at latest version.${NOCOLOR}"
	exit 0
else
	echo -e "${Y}New major version available OR force parameter provided.${NOCOLOR}"
fi


# import and check gpg
contributorSig=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "manifest" | grep -Po "manifest-guggero-.*\.sig" | awk 'NR==1')
manifestTxt=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "manifest" | grep -Po "manifest-v.*\.txt" | awk 'NR==1')
wget -q $rootDl$newVersion/$contributorSig
wget -q $rootDl$newVersion/$manifestTxt
curl -s  https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/guggero.asc | gpg --import > /dev/null 2>&1
gpgCheck=$(/usr/bin/gpg --verify $contributorSig $manifestTxt 2>&1 | grep -iq "Good signature " && echo $?)
if [[ $gpgCheck ]]; then
	echo -e "${G}Good Signature!${NOCOLOR}"
	rm -rf $contributorSig
else
	echo -e "${R}Bad Signature!${NOCOLOR}"
	rm -rf $contributorSig
	exit 1
fi


# Download & verify file integrity then extract content
echo -e "${Y}Downloading, verifying and extracting contents.${NOCOLOR}"
newFullUrl=$rootDl$newVersion/lnd-linux-amd64-$newVersion.tar.gz
newFolder=lnd-linux-amd64-$newVersion
newFile=$newFolder.tar.gz
rm -rf $newFolder && rm -rf $newFile
wget -q $newFullUrl
shaSumCheck=$(/usr/bin/sha256sum --check $manifestTxt --ignore-missing 2>&1 | grep -iq "OK" && echo $?)
if [[ $shaSumCheck ]]; then
	echo -e "${G}SHA256 hash check succeeded!${NOCOLOR}"
else
	echo -e "${R}Bad hash!${NOCOLOR}"
	exit 1
fi
rm -rf $manifestTxt 
tar -xzf $newFile


# Install the new version
# Stop the LND service
echo -e "${Y}Stopping the LND service.${NOCOLOR}"
sudo systemctl stop lnd
echo -e "${G}Done${NOCOLOR}"
# Install new LND version
echo -e "${Y}Installing new binaries.${NOCOLOR}"
folderWStar="${newFolder}"'/*'
sudo install -m 0755 -o root -g root -t /usr/local/bin $folderWStar
echo -e "${G}Done${NOCOLOR}"
# Restart LND service
echo -e "${Y}Starting the LND service.${NOCOLOR}"
sudo systemctl start lnd
echo -e "${G}Done${NOCOLOR}"
echo -e "${C}Successfully upgraded LND!${NOCOLOR}"
