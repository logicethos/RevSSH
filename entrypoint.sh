#!/bin/sh

#Create env vairables for plugin
printf "SSHHOST=$SSHHOST\nSSHPORT=$SSHPORT\nHTTPSPORT=$HTTPSPORT" >  /etc/profile.d/revssh.sh

#Start sshd
mkdir /var/run/sshd
chmod 0755 /var/run/sshd
/usr/sbin/sshd
 
#Start Gateone 
/usr/local/bin/update_and_run_gateone --log_file_prefix=/gateone/logs/gateone.log
