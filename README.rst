Reverse SSH server (with optional Web front end)
----------

SSH login to a Linux device behind firewall/mobile networks.  Suggested uses:

 - Support customers/friends computers
 - Remote control IOT devices
 - Development/Debugging




Requirements:
-------------

- Server/Desktop with Docker, and public IP address.
- Devices to connect to. Must have an SSH client and wget or curl



To install/run on server:
-----------

.. code::

    docker run -d --cap-add=SYS_PTRACE \
               -e "SSHHOST=<host>" \                   #This is the public IP or Domain
               -p <port>:8000 -e "HTTPSPORT=<port>" \  #HTTPS port (e.g 8000)
               -p <port>:22  -e "SSHPORT=<port>" \     #SSH port (e.g 221)
               --cap-add=SYS_PTRACE \
               logicethos/revssh

e.g:
.. code::

    docker run -d -e "SSHHOST=rssh.mydomain.com" -p 8000:8000 -e "HTTPSPORT=8000" -p 221:22  -e "SSHPORT=221" --restart always logicethos/revssh



To Use:
-------

Go to `https://<host>:<https port>` and click on "Terminal SSH".  Type in:

.. code::

ssh://admin@localhost:22

OR from another console
.. code::

    ssh admin@<host> -p <ssh port>

**The default password is admin.  Change this!**


.. figure:: https://raw.githubusercontent.com/logicethos/RevSSH/master/screenshot1.png

At the top of the login screen, you will see a wget & curl command line.  One of these can be used to initiate connection from the remote client.  Or you can visit 
.. code::

https://<host>:<https port>/info for instructions.
