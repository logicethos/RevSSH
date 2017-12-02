#!/bin/bash
#
# RevSSH
# MIT Licence - (c)2017 Stuart Johnson, Logic Ethos Ltd.

RUNAPP="python /home/admin/ssh.py"
source /etc/profile


display()
{
 clear
 echo "Reverse SSH Terminal"
 echo "wget https://$SSHHOST:$HTTPSPORT/connect --no-check-certificate -O connect.sh; sh connect.sh"
 echo "curl -k https://$SSHHOST:$HTTPSPORT/connect -o connect.sh; sh connect.sh"
 echo "======================================================================================="
 echo
 $RUNAPP
 echo
 echo "======================================================================================="
 echo "-> Please enter SSH port to connect."
 echo "-> [ENTER] to refresh status."
 echo "-> 'passwd' to change password."
 echo "-> 'kill <port>' to drop connection."
 echo "-> 'exit' or 'quit'"
}

display
 
while true; do
 
 read port
   
 if  [ "$port" = "" ]; then
   display
   continue
 elif  [ "$port" = "passwd" ]; then
   passwd
 elif [ "$port" = "exit" ] || [ "$port" = "quit" ]; then
   exit
 elif  [[ "$port" =~ kill.* ]]; then
   $RUNAPP $port
 elif [[ $port =~ ^-?[0-9]+$ ]] ; then
    if [[ "$port" -ge 10000  &&  "$port" -le 65535  ]]; then  
      $RUNAPP $port
    else         
      echo "Port out of range"
    fi
   echo
 fi   
done
