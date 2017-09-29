#!/bin/bash

#Executed on every ssh connection attempt, to get known public keys.

user=$1

if [ $user == "remote" ]; then

  for file in /tmp/rsa_*.pub; do
      cat "$file" 
      printf "\n" 
  done

fi  