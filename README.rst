
docker build -t sshtest6 .
docker run -d -p 8000:8000 -p 221:22 -e "SSHHOST=localhost" -e "SSHPORT=221" -e "HTTPSPORT=8000" --cap-add=SYS_PTRACE sshtest6