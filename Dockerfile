#
# GateOne Reverse SSH Plugin
# MIT Licence - (c)2017 Stuart Johnson, Logic Ethos Ltd.
#

# Pull base image.
FROM liftoff/gateone

# Install packages.
RUN \
  apt-get update && \
  apt-get install -y openssh-server joe less findutils lsof python-dateutil sudo && \
  rm -rf /var/lib/apt/lists/*

#Mod sshd
RUN sed -i '/^IgnoreRhosts/s/yes/no/' /etc/ssh/sshd_config
RUN printf "AuthorizedKeysCommand /root/.ssh/remote_auth_script.sh %%u\nAuthorizedKeysCommandUser root" >> /etc/ssh/sshd_config

#Add SUDOers
RUN printf "admin ALL=(root)NOPASSWD:/usr/bin/lsof\nadmin ALL=(root)NOPASSWD:/usr/bin/stat\nadmin ALL=(remote)NOPASSWD:/bin/kill\n" >> /etc/sudoers

#Add Admin user
RUN useradd -ms /home/admin/login.sh admin
RUN echo admin:admin | chpasswd
RUN ["mkdir", "-p", "/home/admin/.ssh"]
RUN ["cp", "/dev/null", "/home/admin/.ssh/authorized_keys"]
RUN ["chown", "-R", "admin:admin", "/home/admin"]
RUN ["chmod", "700", "/home/admin/.ssh"]
RUN ["chmod", "600", "/home/admin/.ssh/authorized_keys"]
RUN ["chmod", "go-w", "/home/admin"]
RUN sudo -u admin ssh-keygen -t rsa -N '' -f /home/admin/.ssh/id_rsa

#Add Remote user
RUN useradd -ms /usr/sbin/nologin remote
RUN ["mkdir", "-p", "/home/remote/.ssh"]
RUN ["cp", "/dev/null", "/home/remote/.ssh/authorized_keys"]
RUN ["chown", "-R", "remote:remote", "/home/remote"]
RUN ["chmod", "700", "/home/remote/.ssh"]
RUN ["chmod", "600", "/home/remote/.ssh/authorized_keys"]
RUN ["chmod", "go-w", "/home/remote"]

# Add files.
ADD ssh.py /home/admin/ssh.py
ADD login.sh /home/admin/login.sh
RUN ["chmod", "+x", "/home/admin/login.sh"]
ADD entrypoint.sh /entrypoint.sh
RUN ["chmod", "+x", "/entrypoint.sh"]
RUN ["chown", "-R", "admin", "/home/admin"]

#Setup SSH key scripting
RUN ["mkdir", "-p", "/root/.ssh"]
RUN ["cp", "/dev/null", "/root/.ssh/authorized_keys"]
RUN ["chmod", "700", "/root/.ssh"]
RUN ["chmod", "600", "/root/.ssh/authorized_keys"]
RUN ["chmod", "go-w", "/root"]
ADD remote_auth_script.sh /root/.ssh/remote_auth_script.sh
RUN ["chmod", "700", "/root/.ssh/remote_auth_script.sh"]

# Add Gateone plugin
ADD GateOne_Plugin /GateOne_Plugin
RUN mv /GateOne_Plugin `find /usr/local/lib/*/dist-packages/*/gateone/applications/terminal -name 'plugins'`/revssh
RUN chmod +x `find /usr/local/lib/*/dist-packages/*/gateone/applications/terminal -name 'plugins'`/revssh/makekey.sh

RUN rm -R `find /usr/local/lib/*/dist-packages/*/gateone/applications/terminal -name 'plugins'`/example
RUN mv `find /usr/local/lib/*/dist-packages/*/gateone/applications/terminal -name 'plugins'`/revssh `find /usr/local/lib/*/dist-packages/*/gateone/applications/terminal -name 'plugins'`/example


# Set environment variables.
ENV HOME /root
ENV TERM=xterm
ENV SSHHOST=_host_not_set_
ENV SSHPORT=22
ENV HTTPSPORT=8000

EXPOSE 22
EXPOSE 8000

# Define working directory.
WORKDIR /root

# Define default command.
ENTRYPOINT ["/entrypoint.sh"]
