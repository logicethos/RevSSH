# -*- coding: utf-8 -*-
#
# RevSSH
# MIT Licence - (c)2017 Stuart Johnson, Logic Ethos Ltd.

__doc__ = """\
A plugin for reverse ssh

"""

__version__ = '1.0'
__license__ = "Apache 2.0"
__version_info__ = (1, 0)
__author__ = 'Stuart Johnson <stuart@logicethos.com>'

import os
import threading
from gateone.core.server import BaseHandler
import tornado.escape
import tornado.web
from subprocess import call
import datetime
from gateone.core.log import go_logger
import glob

# Globals
PLUGIN_PATH = os.path.split(__file__)[0] # Path to our plugin's directory
ssh_log = go_logger("gateone.terminal.revssh", plugin='revssh')

connectFilename = "connect.sh"

portCounterMin=10000
portCounterMax=19999
portCounter=portCounterMin
portCounterLock = threading.Lock()
RSAPathPrefix="/tmp/rsa_"
sshpyPath="/home/admin/ssh.py"

with open('/home/admin/.ssh/id_rsa.pub','r') as f:
    rsapub = f.read().rstrip()


sshPort=os.environ['SSHPORT']

#Timer to delete old keys
def runSshPy():
  try:
    call(["python",sshpyPath,"clean"])
  except Exception as e:
    ssh_log.info(e)
  threading.Timer(600, runSshPy).start()

#Start timer
runSshPy()

# https://<host>/connect
class RevSSHHandler(BaseHandler):

    def get(self):			#Get bash script for remote login

        global portCounter
    
        host = self.request.host.split(":")[0]
        hosturl = "https://" + self.request.host
    
        with portCounterLock:
            self.add_header("Content-type","application/zip")
            self.add_header("Content-Disposition","attachment; filename=\"" + connectFilename + "\"")
            self.render(
                os.path.join(PLUGIN_PATH,connectFilename), # The path to a template file
                PORT=portCounter,
                SSHHOST = host,
                HOSTURL = hosturl,
                REMOTEIP = self.request.remote_ip,
                SSHPORT = sshPort,
                RSAURL = hosturl + "/rsa",
                RSAPUBURL = hosturl + "/rsapub",
                RSAPUB = rsapub
                )
            portCounter += 1
            if portCounter > portCounterMax:
                portCounter = portCounterMin

# https://<host>/rsa
class RSAHandler(BaseHandler):

    def get(self):			#Get a temporary public key (for passwordless login)

        filename=RSAPathPrefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S%f.rsa")
        

        call([os.path.join(PLUGIN_PATH,"makekey.sh"),
             filename,
             self.get_argument("user","root",True),
             self.get_argument("host","localhost",True),
             self.get_argument("port","0",True)])

        if os.path.exists(filename):
           self.add_header("Content-type","application/zip")
           self.add_header("Content-Disposition","attachment; filename=\"revssh_rsa\"")
           self.render(filename)
        else:
           self.write("Error creating key")

# https://<host>/rsapsub
class RSAPubHandler(BaseHandler):

    def get(self):  			#Get user admins's public key

        filename="/home/admin/.ssh/id_rsa.pub"

        if os.path.exists(filename):
           self.add_header("Content-type","application/zip")
           self.add_header("Content-Disposition","attachment; filename=\"revssh_rsa\"")
           self.render(filename)
        else:
           self.write("Error - key not found")

    def post(self):			#Uploaded clients public key 

        #ssh_log.info(self.request.files)
        
        user = self.get_argument("user","root",True)
        host = self.get_argument("host","localhost",True)
        port = self.get_argument("port","0",True)

        filename=RSAPathPrefix + datetime.datetime.now().strftime("%Y%m%d%H%M%S%f.rsa.pub")
        
        file_body = self.request.files['file'][0]['body']
        if file_body.startswith("ssh-rsa"):
           rsadata = file_body.split(" ",2)
           output_file = open(filename, 'w')
           output_file.write("{0} {1} {2}@{3} #{4}".format(rsadata[0],rsadata[1],user,host,port))
        else:
           ssh_log.info("Incorrect ssh_rsa upload")


hooks = {
    'Web': [(r"/connect", RevSSHHandler), (r"/rsa", RSAHandler), (r"/rsapub", RSAPubHandler)]
     }
