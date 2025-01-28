# rebolt.sh is a shell script that enterprise software developers use when
# restarting remote servers. These steps are in order, and order does matter.
# One may edit this script to include additional domains to be certified by
# letsencrypt.
#!/bin/bash

EMAIL="LETS_ENCRYPT_CONTACT_EMAIL_HERE"

# Use letsencrypts `certbot` to renew tls certs, this isn't necessary for every
# reboot, only when the certs expire or when we need to add new domains to
# them.
sudo certbot certonly --noninteractive --agree-tos --cert-name boltorg \
    -d hrtsfld.xyz -d walboard.xyz -d tagmachine.xyz -d btstrmr.xyz \
    -d bolt-marketing.org -d owlen.hrtsfld.xyz -d statui.hrtsfld.xyz \
    -d sigma-firma.org -d sigma-firma.com -d sigmafirma.com -d sigmafirma.org \
    -d mysterygift.org -m $EMAIL --standalone

# Copy the cert files produced by the previous command into a safer directory,
# here we use a directory in our users home folder, tlsCerts/
sudo cp /etc/letsencrypt/live/boltorg/fullchain.pem $HOME/tlsCerts/fullchain.pem
sudo cp /etc/letsencrypt/live/boltorg/privkey.pem $HOME/tlsCerts/privkey.pem

# The tls server (bp - bolt proxy) won't work if we don't change the owner of
# these files from root to a regular user. This is because bp is designed to
# run as a regular user, as opposed to root, which is probably unsafe...
sudo chown $USER tlsCerts/*

# Here, http(s) traffic is redirected from ports 80 and 443 to 8080 and 8443 
# respectively. This is also done for safety purposes, as low ports require 
# root privileges, and this allows our server (bp) to be run as a regular user,
# on ports 8443 and 8080. 
# NOTE: This has to be run *AFTER* running certbot or certbot won't work.
sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Here we restart our server (bp), by first using pkill to stop any running
# instances of it, then we go into each folder in $HOME/live and build the apps
# (websites) using the name of the folders as the command/name of the output 
# binary (which is also be the command to start the app). We then run pkill to 
# make sure an instance of the app isn't already running, before running the 
# app and sending it to the background (&), and then finally restarting bp,
# and sending it to the background. NOTE: Keep a look out for errors
pkill bp || true; cd
for d in $HOME/live/*/ ; do
    cd $d
    name=$(basename ${d})
    echo $name $d
    go build -o $HOME/bin/$name

    pkill -f $name
    $name &
done
bp &
