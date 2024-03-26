# docker login
# docker build -t kodmandvl/myrocky88:m .
# docker push kodmandvl/myrocky88:m
# docker pull kodmandvl/myrocky88:m
# docker tag kodmandvl/myrocky88:m kodmandvl/myrocky88:latest
# docker push kodmandvl/myrocky88:latest
# docker pull kodmandvl/myrocky88:latest
# docker images | grep myrocky88
# docker run -d -p 8822:22 --name myrocky88 -h myrocky88 kodmandvl/myrocky88:m
# docker exec -it myrocky88 /bin/bash
# ssh -p 8822 admin@localhost
# docker logs myrocky88
FROM rockylinux:8.8
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
RUN adduser -u 1032 postgres && \
    dnf install -y epel-release && \
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf install -y openssh-server openssh-clients grep gawk sed bc mc net-tools telnet sudo \
                   lsof tzdata wget curl man zip unzip binutils psmisc nano vi jq \
                   tar bzip2 gzip p7zip p7zip-plugins \
                   openssl bash-completion passwd \
                   findutils procps-ng glibc-langpack-en && \
    dnf -qy module disable postgresql && \
    dnf --enablerepo=powertools install perl-IPC-Run -y && \
    echo 'admin   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    adduser -u 1088 admin && \
    ssh-keygen -A
EXPOSE 22
RUN rm -rf /run/nologin
CMD ["/usr/sbin/sshd","-D"]
