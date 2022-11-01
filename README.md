# upgrade-lnd
Code to automatically update lnd (currently only for Debian Linux AMD64)

## To Execute, run it with sudo:
```
sudo ./upgrade-lnd.sh
```
It will download the binaries to the "/tmp" directory. If the version is the same, it will delete the file and directory before downloading a fresh copy.
