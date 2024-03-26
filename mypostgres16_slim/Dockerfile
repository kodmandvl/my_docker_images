####################################################################################################
# docker login
# docker build -t kodmandvl/mypostgres16:slim-rocky88 .
# docker push kodmandvl/mypostgres16:slim-rocky88
# docker pull kodmandvl/mypostgres16:slim-rocky88
# docker images | grep mypostgres16
## Example:
# mkdir -p ${HOME}/temp/mypostgres16 && chmod 777 ${HOME}/temp/mypostgres16
# docker run -d -p 5432:5432 -v ${HOME}/temp/mypostgres16:/pgdata --name mypostgres16 -h mypostgres16 kodmandvl/mypostgres16:slim-rocky88
## Set password for postgres user (if you need):
# docker exec -it mypostgres16 /bin/bash /home/postgres/set_password.sh
# psql postgres://postgres@127.0.0.1:5432/postgres -c "select inet_server_addr(), inet_server_port(), version(), now();"
# docker logs mypostgres16 -f
# docker exec -it mypostgres16 /bin/bash
## Start Open SSH Server on container (if you need):
# docker exec -d mypostgres16 /bin/bash /home/postgres/start_sshd.sh
####################################################################################################
FROM rockylinux:8.8
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
RUN adduser -u 1032 postgres && \
    dnf install -y epel-release && \
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -qy module disable postgresql && \
    dnf --enablerepo=powertools install perl-IPC-Run -y && \
    dnf install -y openssh-server openssh-clients grep gawk sed bc mc net-tools telnet sudo \
                   lsof tzdata wget curl man binutils psmisc nano vi \
                   tar gzip \
                   openssl bash-completion passwd \
                   findutils procps-ng glibc-langpack-en && \
    dnf install -y postgresql16-server postgresql16-libs postgresql16 postgresql16-contrib pg_stat_kcache_16 \
                   libpq5 && \
    echo 'postgres   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    dnf install -y http://repo.postgrespro.ru/pg_probackup/rpm/2.5.13/rhel-8-x86_64/pg_probackup-16-2.5.13-1.48efe9086f9a9171b1e51fdf9105edcd667332a4.x86_64.rpm && \
    su -l postgres -c "wget https://github.com/zubkov-andrei/pg_profile/releases/download/4.3/pg_profile--4.3.tar.gz" && \
    tar xzvf /home/postgres/pg_profile--4.3.tar.gz --directory /usr/pgsql-16/share/extension
####################################################################################################
COPY postgres16.env /home/postgres/postgres16.env
COPY entrypoint.sh /home/postgres/entrypoint.sh
COPY set_password.sh /home/postgres/set_password.sh
COPY start_sshd.sh /home/postgres/start_sshd.sh
COPY psqlrc /home/postgres/.psqlrc
RUN echo 'source /home/postgres/postgres16.env' >> /home/postgres/.bashrc && \
    echo 'source /home/postgres/postgres16.env' >> /home/postgres/.bash_profile && \
    chown -R postgres:postgres /home/postgres && \
    chmod 755 /home/postgres/*.sh && \
    mkdir -p /pgdata/16/data && \
    chown -R postgres:postgres /pgdata && \
    chmod -R 700 /pgdata
USER postgres
EXPOSE 5432
WORKDIR /home/postgres
CMD ["/home/postgres/entrypoint.sh"]
####################################################################################################
