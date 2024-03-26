# docker login
# docker build -t kodmandvl/myrocky88:xxxl .
# docker push kodmandvl/myrocky88:xxxl
# docker pull kodmandvl/myrocky88:xxxl
# docker images | grep myrocky88
# docker run -d -p 8822:22 --name myrocky88 -h myrocky88 kodmandvl/myrocky88:xxxl
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
    dnf install -y grep gawk sed bc mc nmap tcpdump net-tools bind-utils telnet python3 python3-pip git sudo \
                   lsof tzdata wget curl man zip unzip binutils psmisc nano vim jq cifs-utils \
                   rlwrap xcalc xauth pwgen tar bzip2 gzip gcc make perl cryptsetup nfs-utils \
                   libpq5 chrony python3-virtualenv sshpass p7zip p7zip-plugins p7zip-doc \
                   htop atop iftop traceroute yum-utils haproxy libaio glibc libnsl \
                   python3-psycopg3 python3.11 python3.11-psycopg2 python3.11-pip \
                   ansible patroni patroni-etcd tmux openssl bash-completion passwd && \
    dnf -qy module disable postgresql && \
    dnf install -y postgresql16-server postgresql16-libs postgresql16 postgresql16-contrib pg_stat_kcache_16 \
                   pgbadger pgcenter pgbouncer pg_top && \
    dnf install -y https://download.oracle.com/otn_software/linux/instantclient/1919000/oracle-instantclient19.19-basic-19.19.0.0.0-1.x86_64.rpm && \
    dnf install -y https://download.oracle.com/otn_software/linux/instantclient/1919000/oracle-instantclient19.19-tools-19.19.0.0.0-1.x86_64.rpm && \
    dnf install -y https://download.oracle.com/otn_software/linux/instantclient/1919000/oracle-instantclient19.19-sqlplus-19.19.0.0.0-1.x86_64.rpm && \
    dnf --enablerepo=powertools install perl-IPC-Run -y && \
    echo 'admin   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    adduser -u 1088 admin && \
    ssh-keygen -A && \
    cd /usr/local/bin && \
    wget 192.168.50.53:10184/etcd && \
    wget 192.168.50.53:10184/etcdctl && \
    wget 192.168.50.53:10184/etcdutl && \
    wget 192.168.50.53:10184/kubectl && \
    wget 192.168.50.53:10184/helm && \
    wget 192.168.50.53:10184/k9s && \
    wget 192.168.50.53:10184/ketall && \
    wget 192.168.50.53:10184/kubectl_ctx.sh && \
    wget 192.168.50.53:10184/kubectl_ns.sh && \
    wget 192.168.50.53:10184/kubectl-tree && \
    wget 192.168.50.53:10184/kubectl-who-can && \
    wget 192.168.50.53:10184/kubectx && \
    wget 192.168.50.53:10184/kubens && \
    wget 192.168.50.53:10184/kubespy && \
    wget 192.168.50.53:10184/outdated && \
    wget 192.168.50.53:10184/kubebox && \
    chmod 755 /usr/local/bin/* && \
    su -l postgres -c "git clone https://github.com/zalando/patroni.git" && \
    dnf install -y http://repo.postgrespro.ru/pg_probackup/rpm/2.5.13/rhel-8-x86_64/pg_probackup-16-2.5.13-1.48efe9086f9a9171b1e51fdf9105edcd667332a4.x86_64.rpm && \
    su -l postgres -c "wget https://github.com/zubkov-andrei/pg_profile/releases/download/4.3/pg_profile--4.3.tar.gz" && \
    tar xzvf /home/postgres/pg_profile--4.3.tar.gz --directory /usr/pgsql-16/share/extension && \
    dnf install -y firefox && \
    dnf install -y gedit
EXPOSE 22
RUN rm -rf /run/nologin
CMD ["/usr/sbin/sshd","-D"]
