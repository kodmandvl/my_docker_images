# docker login
# docker build -t kodmandvl/myrocky88:s .
# docker push kodmandvl/myrocky88:s
# docker pull kodmandvl/myrocky88:s
# docker images | grep myrocky88
# docker run -d -p 8822:22 --name myrocky88 -h myrocky88 kodmandvl/myrocky88:s
# docker exec -it myrocky88 /bin/bash
# ssh -p 8822 admin@localhost
# docker logs myrocky88
FROM rockylinux:8.8
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
RUN adduser -u 1032 postgres && \
    dnf install -y openssh-server sudo passwd vi nano tar gzip gawk sed grep && \
    echo 'admin   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    adduser -u 1088 admin && \
    ssh-keygen -A
EXPOSE 22
RUN rm -rf /run/nologin
CMD ["/usr/sbin/sshd","-D"]
