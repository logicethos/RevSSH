#!/bin/bash
#
# Script to connect to a Reverse SSH server
# Stuart Johnson, Logic Ethos Ltd

DIR_SSHKEYS=~/.ssh 
FILE_SSHKEYS=$DIR_SSHKEYS/authorized_keys
FILE_SSHRSA=rssh_id_rsa
RSA="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/+k3Wt81w6Cc2YduOb7TzpU+G7FD5K1kqdzwajpw1KISeenVuXKVnTk8N5uGu7QfyVgpW5yao9mFySbdgDLRZYzesHKhtTeJDljdEbfggd9dvbpH16PO70tbpftnTovs8IVkhuR+5/JUCMsg7wNMWgtE4+7y2zL1PirfHgASvGLwSHzWC4tqiDxXUaQqb1GFLWsU2NtnpMawSRy8ld4itgmvvvw3KvRDsxKEfusmeIGH4+VenonIjZbDcuE7uWTMk05Z43k9ziMOiM78JnYOCU1qRwGL8BWMN7/Xx70CCsYRtNwsyBKFBdddXAsie1sHIlU8T6hWBDxNxaKTy3ZMr admin@d4f93cc44884"


if ! command -v "ssh" >/dev/null 2>&1; then
  echo "ssh not found"
  exit
fi 
   
if command -v "curl" >/dev/null 2>&1; then IFCURL=true; fi
if command -v "wget" >/dev/null 2>&1; then IFWGET=true; fi
if command -v "ssh-keygen" >/dev/null 2>&1; then IFKEYGEN=true; fi

if [ "$IFCURL" != true ] && [ "$IFWGET" != true ]; then
  echo "curl or wget not found"
  exit 1
fi


#Create local .ssh directory if non-existant
if [ ! -d $DIR_SSHKEYS ]; then
  echo "local .ssh directory missing...creating"
  mkdir -p ~/.ssh
  chmod 700 /home/admin/.ssh
  chmod go-w ~
fi

#Create authorized_keys file if non-existant
if [ ! -f $FILE_SSHKEYS ]; then 
  echo ".ssh/authorized_keys missing...creating"
  cp /dev/null $FILE_SSHKEYS
  chmod 600 $FILE_SSHKEYS
fi

#Add public key, if not already in authorized_keys
RSA_Snip=$(echo "$RSA" | dd bs=9 count=50 2>/dev/null)
if ! grep -q "$RSA_Snip" $FILE_SSHKEYS; then
  echo "adding server's public key to authorized_keys"
  echo "$RSA" >> $FILE_SSHKEYS
fi

#Try and make a private key
if [ "$IFKEYGEN" = true ]; then
   echo "making private key..."
   ssh-keygen -q -t rsa -N '' -f "$FILE_SSHRSA"
fi    
       
#Manage keys
if [ -f $FILE_SSHRSA ]; then  #Keys made - upload public key
  echo "uploading public key to server..."
  if [ $IFCURL = true ]; then
     curl -k -F "file=@$FILE_SSHRSA.pub;filename=id_rsa.pub" "https://localhost:8000/rsapub?host=`hostname`&user=$USER&port=10005"
  elif [ $IFWGET = true ]; then
     printf "%sFILEUPLOAD\r\nContent-Disposition: form-data; name=\"file\"; filename=\"id_rsa.pub\";\r\nContent-Type: application/octet-stream\r\nMedia Type: application/octet-stream\r\n\r\n$(cat $FILE_SSHRSA.pub)\r\n\r\n--FILEUPLOAD--" "--" > wget_postfile
     wget --no-check-certificate --header="Content-type: multipart/form-data; boundary=FILEUPLOAD" --post-file wget_postfile "https://localhost:8000/rsapub?host=`hostname`&user=$USER&port=10000"
     rm wget_postfile
  fi   
else #Request a new key from the server
  echo "downloading private key from server"
  if [ "$IFWGET" = true ]; then
     wget "https://localhost:8000/rsa?host=`hostname`&user=$USER&port=10005" --no-check-certificate  -O $FILE_SSHRSA 
  elif [ "$IFCURL" = true ]; then
     curl -k -o "$FILE_SSHRSA" "https://localhost:8000/rsa?host=`hostname`&user=$USER&port=10005"
  fi    
fi

#If we have the key, then connect
if [ -f $FILE_SSHRSA ]; then
   chmod 0600 $FILE_SSHRSA
   #CONNECT
   ssh -o 'StrictHostKeyChecking=no' -fN -i $FILE_SSHRSA -R 10005:localhost:22 remote@localhost -p221
   if [ $? = 0 ]; then
     echo "CONNECTED"
   else
     echo "FAILED TO CONNECT"
   fi
else
   echo "Unable to find keys"
fi

#Cleanup
rm $FILE_SSHRSA*
rm `basename "$0"`
