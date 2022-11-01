# upgrade-lnd
Code to automatically upgrade lnd (currently only for Debian on AMD64)

## To Execute, run it with sudo:
```
sudo ./upgrade-lnd.sh
```
It will download the binaries to the "/tmp" directory. If the version is the same, it will delete the file and directory before downloading a fresh copy.
