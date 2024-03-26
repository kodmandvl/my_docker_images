# docker login
# docker build -t kodmandvl/myrocky88:l .
# docker push kodmandvl/myrocky88:l
# docker pull kodmandvl/myrocky88:l
# docker images | grep myrocky88
# docker run -d -p 8822:22 --name myrocky88 -h myrocky88 kodmandvl/myrocky88:l
# docker exec -it myrocky88 /bin/bash
# ssh -p 8822 admin@localhost
# docker logs myrocky88
FROM rockylinux:8.8
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
RUN dnf update -y && \
    adduser -u 1032 postgres && \
    dnf install -y epel-release && \
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf install -y openssh-server && \
    dnf install -y grep gawk sed bc mc nmap tcpdump net-tools bind-utils telnet git sudo \
                   lsof tzdata wget curl man zip unzip binutils psmisc nano vim jq \
                   rlwrap pwgen tar bzip2 gzip \
                   sshpass p7zip p7zip-plugins \
                   htop atop iftop traceroute yum-utils libaio glibc libnsl \
                   tmux openssl bash-completion passwd && \
    dnf -qy module disable postgresql && \
    dnf --enablerepo=powertools install perl-IPC-Run -y && \
    echo 'admin   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    adduser -u 1088 admin && \
    ssh-keygen -A
EXPOSE 22
RUN rm -rf /run/nologin
CMD ["/usr/sbin/sshd","-D"]
