# upgrade-lnd
Code to automatically upgrade lnd (currently only for Debian on AMD64)

##  Parameters
```-f``` Forcefully download and install the latest version.  
```-p``` Subscribe to pre-releases (rc1, rc2 etc.).

## To Execute, run it with sudo:
```
sudo ./upgrade-lnd.sh -f -p
```
It will download the binaries to the "/tmp" directory. If the version is the same, it will delete the file and directory before downloading a fresh copy.

## Pipeline
My next step is to add an architecture parameter to support different systems (they would need to support BASH).

## Current Issues
I'm noticing that my ```curl``` commands occasionally hang, I'm not sure why. I'll try to implement a timeout / retry function to fix it.
