## GateOne Reverse SSH Plugin
# MIT Licence - (c)2017 Stuart Johnson, Logic Ethos Ltd.

#//sshd    7346 rssh    8u  IPv6 134447989      0t0  TCP [::1]:10021 (LISTEN)
#//sshd    7346 rssh    9u  IPv4 134447990      0t0  TCP localhost:10021 (LISTEN)

import os
import sys
import subprocess
import re
from datetime import datetime, timedelta
import glob
import time
from dateutil import parser

file_lsof = "/usr/bin/lsof"
file_keys = "/tmp/*rsa.pub"
port = 0

class RunModeEnum:
 Display=0
 Kill=1
 Connect=2
 Clean=3

RSAPathPrefix="/tmp/rsa_"
oldfiledate = RSAPathPrefix + (datetime.now() - timedelta(minutes=15)).strftime("%Y%m%d%H%M*")



def sec2time(sec):
    ''' Convert seconds to 'D days, HH MM SS' '''
    if hasattr(sec,'__len__'):
        return [sec2time(s) for s in sec]
    m, s = divmod(sec, 60)
    h, m = divmod(m, 60)
    d, h = divmod(h, 24)
    return ('%d days, %02dh %02dm') % (d, h, m)



RunMode = RunModeEnum.Display

for arg in sys.argv:
    if arg == "kill":
        RunMode = RunModeEnum.Kill
    if arg == "clean":
        RunMode = RunModeEnum.Clean
    elif arg.isdigit(): #is arg integer
        if RunMode == RunModeEnum.Kill:
           subprocess.call(["sudo","-u remote","kill", arg ])
        else:
           RunMode = RunModeEnum.Connect
           port=arg
           break

if RunMode == RunModeEnum.Kill:
  sys.exit(0)

#run lsof to get active listening SSH ports
lsofout=None
try:
    lsofout = subprocess.check_output(["sudo", file_lsof,"-P","-F","pPn","-i", "tcp:10000-19999"]).split("\n")
except subprocess.CalledProcessError,e:
    if lsofout is None:
        print "NO ACTIVE CONNECTIONS\n"
    else:
        print "lsof error:", e.output
    for file in glob.glob(oldfiledate):
    #Cleanup any old key files
      if file < oldfiledate: os.remove(file)
      print "Deleted " + file
    sys.exit(0)


#Parse lsof output
waitforp = True;
ssh_list = {}
ssh_list_select = None

for item in lsofout:
    if not item:
      continue    
    if item[0]=="p":  #Pid
      if len(item) > 1:
         pid = int(item[1:])
         ssh_list[pid]=[0,'','',0,''] #port,host,port,file_desc,user
         waitforp=False
      else:
          waitforp=True
      continue
    
    elif waitforp:
       continue
    
    elif item[0]=="n":  #remote host:port
        rhostp=item.split(":")
        ssh_list[pid][0] = rhostp[1]     #port
        ssh_list[pid][1] = rhostp[0][1:] #host

    elif item[0]=="P":  #Protocol
        ssh_list[pid][2]=item[1:]
    
    elif item[0]=="f":  #File descriptor
        ssh_list[pid][3]=item[1:]


authkeysout=None
keyFile_list = {}

#Read all existing public keys, for their ports & usermames. 
for file in glob.glob(file_keys):
  with open(file) as f:
    for line in f:
      keymatch = re.search("((?<= )\S+(?=@))@(\S+).+#(\d+)", line)
      if keymatch and keymatch.group(1) and keymatch.group(2) and keymatch.group(3):
         keyFile_list[keymatch.group(3)] = [keymatch.group(1),file,keymatch.group(2)]

if RunMode == RunModeEnum.Display:
  print "ACTIVE CONNECTIONS\n"

for pid,item in ssh_list.items():
    stats = subprocess.check_output(["sudo", "stat","/proc/{0}/fd/{1}".format(pid,item[3])])
    timestampstring = re.search("(?<=Modify: ).*", stats).group(0)  
    timestamp = parser.parse(timestampstring)      
    timediff = (datetime.now()-timestamp.replace(tzinfo=None)).total_seconds()

    item[1] = keyFile_list[item[0]][2] if item[0] in keyFile_list  else "<??>"
    item[4] = keyFile_list[item[0]][0] if item[0] in keyFile_list  else "<??>"
    if RunMode == RunModeEnum.Display:
        print "PORT: {0} \t{1}@{2} \t(PID:{3})\t{4}".format(item[0],item[4],item[1].ljust(30-len(item[4])),pid,sec2time(timediff))

    if item[0]==port:
       ssh_list_select = item




if RunMode == RunModeEnum.Connect:
    if ssh_list_select:
      subprocess.call(["clear"])
      subprocess.call(r"ssh -o 'StrictHostKeyChecking=no' -o 'UserKnownHostsFile /dev/null' -o 'LogLevel=ERROR' {0}@localhost -p {1}".format(ssh_list_select[4],ssh_list_select[0]),shell=True)
    else:
      print "Port not found"

elif RunMode == RunModeEnum.Clean:
  #Clean old Key files 
  activePortList = [ ]#Get list of active ports
  for key, item in ssh_list.items():
    activePortList.append(item[0])
  #If we have a key file for a non active port, and it's not recent, delete
  for port,item in keyFile_list.items():
    if not port in activePortList:
       if item[1] < oldfiledate:
         os.remove(item[1])
         print "Deleted "+item[1]

