# upgrade-lnd
Code to automatically upgrade lnd (currently only for Debian on AMD64)

## About
Running it with the ```-f``` parameter will force it to download the latest version with any new commits.

##  Parameters
```-f``` Forcefully download and install the latest version.

## To Execute, run it with sudo:
```
sudo ./upgrade-lnd.sh -f
```
It will download the binaries to the "/tmp" directory. If the version is the same, it will delete the file and directory before downloading a fresh copy.
