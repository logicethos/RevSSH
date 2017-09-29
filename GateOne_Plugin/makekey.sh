#!/bin/bash
#Called by revssh.py plugin when remote requests rsa key file. https://<thishost>:rsa
#this provides passwordless login

filename=$1
user=$2
host=$3
port=$4


#Generate key
ssh-keygen -q -t rsa -N '' -f $filename

#Change public key file, replacing user@host and adding #port
sed -i -E "s/\s\w\S+@.+/ $user@$host #$port/" $filename.pub
