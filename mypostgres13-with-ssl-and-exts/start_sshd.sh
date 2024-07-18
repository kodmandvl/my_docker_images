echo
echo Start Open SSH Server
echo
sudo su - -c 'ssh-keygen -A && rm -rf /run/nologin && nohup /usr/sbin/sshd -D &'
if [ `ps -ef | grep usr.sbin.sshd..D | grep -v grep | wc -l` -ne 0 ]
then
  echo
  echo "Open SSH Server: OK"
else
  echo
  echo "Open SSH Server: FAIL"
fi
echo
echo Done.
echo
