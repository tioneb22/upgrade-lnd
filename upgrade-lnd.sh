#!/bin/bash
clear


# color code setup
##################
G='\033[0;32m' 		# green color
Y='\033[1;33m' 		# yellow color
R='\033[0;31m' 		# red color
C='\033[1;36m' 		# cyan color
NOCOLOR='\033[0m' 	# no color
cd /tmp


# parameter setup
#################
while getopts "fp" opt; do 
    case $opt in
        f) force=0;;
		p) subtopre=0;;
		*)echo "invalid parameter" && exit 1;;
    esac
done
if ! [ -z "$force" ]; then
	echo -e "Force flag present"
fi
if ! [ -z "$subtopre" ]; then
	echo -e "Pre-release flag present"
fi


# get version information
#########################
echo -e "Getting current and new version info."
currentVersion=$(lnd --version | grep -Po "commit=\K.*$")
newVersion=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep -Po "^.*>lnd \Kv.*</h2>" | awk -F"<" '{print $1}'| awk 'NR==1')


# check for pre-releases if subscribed to them
##############################################
if ! [ -z "$subtopre" ]; then
	echo -e "${Y}Subscribed to pre-releases, checking for latest ${NOCOLOR}"
	# check for pre-release (rc) versions then loop to find the biggest one
	# get array of rc pre-releases
	rcArray=(`/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep -Po "^.*>lnd \Kv.*</h2>" | awk -F"<" '{print $1}' | grep "$newVersion" | grep -Po ".rc\K.*$"`)
	# ${#rcArray[@]} 	# array lenght
	# ${rcArray[2]}		# array item
	declare -i x=0
	for i in "${rcArray[@]}"
	do
		if [ "$i" -gt "$x" ];then
			x="$(($i))"
		fi
	done

	# if rcArray isn't empty, then append biggest rc pre-release to version variable
	if [ ${#rcArray[@]} -eq 0 ];then
		echo -e "${Y}No RC pre-releases ${NOCOLOR}" 
	else
		# update new version variable with pre-release
		newVersion=$newVersion".rc"$x
		echo -e "${Y}RC pre-release detected: ${x} ${NOCOLOR}" 
	fi
else
	echo -e "${Y}Not subscribed to pre-releases ${NOCOLOR}"
fi


# Version and force flag check
##############################
if [ "$currentVersion" == "$newVersion" ] && [ -z "$force" ]; then
	echo -e "${G}Already at latest version.${NOCOLOR}"
	exit 0
else
	echo -e "${Y}New version available or force parameter provided.${NOCOLOR}"
	echo -e "${Y}Upgrading from $currentVersion to $newVersion ${NOCOLOR}"
fi


# import and check gpg
######################
rootDl="https://github.com/lightningnetwork/lnd/releases/download/"
contributorSig=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "manifest" | grep "gpg --verify" | grep "$newVersion" | grep -Po "<code>gpg --verify \K.*\.sig" | awk 'NR==1')
manifestTxt=$(/usr/bin/curl -s https://github.com/lightningnetwork/lnd/releases/ | grep "manifest" | grep "gpg --verify" | grep "$newVersion" | grep -Po "<code>gpg --verify.*\Kmanifest-v[0-9].*\.txt" | awk 'NR==1')
wget -q $rootDl$newVersion/$contributorSig
wget -q $rootDl$newVersion/$manifestTxt
# add some well-known keys to check against
curl -s  https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/guggero.asc | gpg --import > /dev/null 2>&1
curl -s  https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/roasbeef.asc | gpg --import > /dev/null 2>&1
curl -s  https://raw.githubusercontent.com/lightningnetwork/lnd/master/scripts/keys/sputn1ck.asc | gpg --import > /dev/null 2>&1
gpgCheck=$(/usr/bin/gpg --verify $contributorSig $manifestTxt 2>&1 | grep -iq "Good signature " && echo $?)
if [[ $gpgCheck ]]; then
	echo -e "${G}Good Signature!${NOCOLOR}"
	rm -rf $contributorSig
else
	echo -e "${R}Bad Signature!${NOCOLOR}"
	rm -rf $contributorSig
	exit 1
fi


# Download, verify and extract
##############################
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


# Install new version
#####################
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