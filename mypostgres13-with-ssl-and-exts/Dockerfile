####################################################################################################
# docker login
# docker build -t kodmandvl/postgres:13-with-ssl-and-exts .
# docker push kodmandvl/postgres:13-with-ssl-and-exts
# docker pull kodmandvl/postgres:13-with-ssl-and-exts
# docker tag kodmandvl/postgres:13-with-ssl-and-exts kodmandvl/postgres:13.15-with-ssl-and-exts
# docker push kodmandvl/postgres:13.15-with-ssl-and-exts
# docker pull kodmandvl/postgres:13.15-with-ssl-and-exts
# docker images | grep kodmandvl.*postgres
## Example without "-v" option:
# docker run -d -p 5432:5432 --name mypg13 -h mypg13 kodmandvl/postgres:13-with-ssl-and-exts
## Example with "-v" option:
# mkdir -p ${HOME}/temp/mypg13 && chmod 777 ${HOME}/temp/mypg13
# docker run -d -p 5432:5432 -v ${HOME}/temp/mypg13:/pgdata --name mypg13 -h mypg13 kodmandvl/postgres:13-with-ssl-and-exts
## Set password for postgres user (if you need):
# docker exec -it mypg13 /bin/bash /home/postgres/set_password.sh
# psql postgres://postgres@127.0.0.1:5432/postgres -c "select inet_server_addr(), inet_server_port(), version(), now();"
# docker logs mypg13 -f
# docker exec -it mypg13 /bin/bash
## Start Open SSH Server on container (if you need):
# docker exec -d mypg13 /bin/bash /home/postgres/start_sshd.sh
####################################################################################################
FROM rockylinux:8.8
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
RUN adduser -u 1032 postgres && \
    dnf install -y epel-release && \
    dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm && \
    dnf -qy module disable postgresql && \
    dnf --enablerepo=powertools install perl-IPC-Run -y && \
    dnf install -y openssh-server openssh-clients grep gawk sed bc mc net-tools telnet sudo \
                   lsof tzdata wget curl man zip unzip binutils psmisc nano vi jq \
                   tar bzip2 gzip p7zip p7zip-plugins \
                   openssl bash-completion passwd \
                   findutils procps-ng glibc-langpack-en && \
    dnf install -y postgresql13-server-13.15 postgresql13-libs-13.15 postgresql13-13.15 postgresql13-contrib-13.15 pg_stat_kcache_13 \
                   libpq5 pgbadger pgcenter pgbouncer pg_top \
                   diffutils which \
                   pg_wait_sampling_13 pgaudit15_13 pg_cron_13 pg_hint_plan_13 pg_failover_slots_13 pgvector_13 && \
    echo 'postgres   ALL=(ALL:ALL)   NOPASSWD:ALL' >> /etc/sudoers && \
    dnf install -y http://repo.postgrespro.ru/pg_probackup/rpm/2.5.13/rhel-8-x86_64/pg_probackup-13-2.5.13-1.48efe9086f9a9171b1e51fdf9105edcd667332a4.x86_64.rpm && \
    su -l postgres -c "wget https://github.com/zubkov-andrei/pg_profile/releases/download/4.3/pg_profile--4.3.tar.gz" && \
    tar xzvf /home/postgres/pg_profile--4.3.tar.gz --directory /usr/pgsql-13/share/extension
####################################################################################################
COPY postgres13.env /home/postgres/postgres13.env
COPY entrypoint.sh /home/postgres/entrypoint.sh
COPY set_password.sh /home/postgres/set_password.sh
COPY start_sshd.sh /home/postgres/start_sshd.sh
COPY psqlrc /home/postgres/.psqlrc
COPY bashrc /home/postgres/.bashrc
RUN echo 'source /home/postgres/postgres13.env' >> /home/postgres/.bashrc && \
    echo 'source /home/postgres/postgres13.env' >> /home/postgres/.bash_profile && \
    chown -R postgres:postgres /home/postgres && \
    chmod 755 /home/postgres/*.sh && \
    mkdir -p /pgdata/13/data && \
    chown -R postgres:postgres /pgdata && \
    chmod -R 700 /pgdata
USER postgres
EXPOSE 5432
WORKDIR /home/postgres
CMD ["/home/postgres/entrypoint.sh"]
####################################################################################################
