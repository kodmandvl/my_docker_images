#!/bin/sh

source /home/postgres/pg5432.env

if [ ! -d "/pgdata/archivewal/from_pg${PGPORT}" ]
then
  echo
  echo /pgdata/archivewal/from_pg${PGPORT} directory does not exist
  echo
  echo Create /pgdata/archivewal/from_pg${PGPORT} directory
  mkdir -pv /pgdata/archivewal/from_pg${PGPORT}
else
  echo
  echo /pgdata/archivewal/from_pg${PGPORT} directory exists
fi

if [ ! -d "${PGDATA}" ]
then
  echo
  echo ${PGDATA} directory does not exist
  echo
  echo Create ${PGDATA} directory
  mkdir -pv ${PGDATA}
else
  echo
  echo ${PGDATA} directory exists
fi

if [ `ls -A1 "${PGDATA}" | wc -l` -eq 0 ]
then
  echo
  echo ${PGDATA} directory is empty
  echo
  echo Init pg5432 instance
  echo
  initdb -k -D ${PGDATA} --locale=en_US.UTF-8
  mkdir -pv ${PGDATA}/log
  mkdir -pv ${PGDATA}/env && cp -av /home/postgres/pg5432.env ${PGDATA}/env/
  echo
  echo Generate certificates
  echo
  mkdir -p ${PGDATA}/ssl && chmod 755 ${PGDATA}/ssl && \
  cd ${PGDATA}/ssl && \
  openssl req -new -nodes -text -out ./root.csr -keyout ./root.key -subj "/CN=TestCA" && \
  openssl x509 -req -in ./root.csr -text -days 36525 -extfile /etc/pki/tls/openssl.cnf -extensions v3_ca -signkey ./root.key -out ./root.crt && \
  openssl req -new -nodes -text -out ./client.csr -keyout ./client.key -subj "/CN=postgres" && \
  openssl x509 -req -in ./client.csr -text -days 36525 -CA ./root.crt -CAkey ./root.key -CAcreateserial -out ./client.crt && \
  openssl req -new -nodes -text -out ./server.csr -keyout ./server.key -subj "/CN=pg13" && \
  openssl x509 -req -in ./server.csr -text -days 36525 -CA ./root.crt -CAkey ./root.key -CAcreateserial -out ./server.crt && \
  chmod 0600 ./*.key && chmod 0644 ./*.crt && echo && cp -av ${PGDATA}/ssl /home/postgres/ssl && echo "Certificates: OK"
  echo
  echo "Add parameters to ${PGDATA}/postgresql.conf file"
  echo "
##################################################
# CONNECTIONS, AUTH, SSL:
listen_addresses = '*'
port = 5432
max_connections = 256
superuser_reserved_connections = 5
password_encryption = 'scram-sha-256'
ssl = on
ssl_cert_file = '/home/postgres/ssl/server.crt'
ssl_key_file = '/home/postgres/ssl/server.key'
ssl_ca_file = '/home/postgres/ssl/root.crt'
# LOGGING:
logging_collector = on
log_line_prefix = '%t [%p]: [%l] app=%a,user=%u,db=%d,client=%h '
log_destination = 'stderr'
log_directory = 'log'
log_filename = 'postgresql-%H.log'
log_truncate_on_rotation = on
log_rotation_age = 1h
log_statement = 'ddl'
log_min_duration_statement = 5000
log_min_error_statement = 'WARNING'
log_timezone = 'Europe/Moscow'
log_connections = on
log_disconnections = on
log_checkpoints = on
log_lock_waits = on
log_replication_commands = on
log_temp_files = 0
# TRACK:
track_activity_query_size = 8192
track_activities = on
track_counts = on
track_io_timing = on
track_functions = 'all'
# SHARED PRELOAD LIBRARIES, SEARCH_PATH, EXTENSIONS, PERFORMANCE, OTHERS:
shared_preload_libraries = 'auth_delay, pgaudit, pg_cron, pg_wait_sampling, pg_stat_statements'
auth_delay.milliseconds = 1000
pg_wait_sampling.history_period = 1000
pg_wait_sampling.profile_period = 1000
pgaudit.log = 'ddl, role, misc_set'
wal_log_hints = on
checkpoint_completion_target = 0.9
random_page_cost = 2
cluster_name = 'pg5432'
##################################################
" >> ${PGDATA}/postgresql.conf
  echo
  echo "Rewrite ${PGDATA}/pg_hba.conf file"
  echo "# New pg_hba.conf file:
hostssl	all          postgres 127.0.0.1/32 cert
hostssl	replication  postgres 127.0.0.1/32 cert
host    all          all      0.0.0.0/0    scram-sha-256
host    replication  all      0.0.0.0/0    scram-sha-256
" > ${PGDATA}/pg_hba.conf
  echo
  echo "Start pg5432 instance"
  echo
  pg_ctl start -D ${PGDATA} -l /home/postgres/pg${PGPORT}.log
  sleep 1
  echo
  echo "Add extensions"
  echo
  psql <<EOF
\c postgres
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pgrowlocks;
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
\c template1
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pgrowlocks;
CREATE EXTENSION IF NOT EXISTS pg_wait_sampling;
EOF
  echo
  echo "Create db size history table and cron job for insert"
  echo
  psql <<EOF
\c postgres
create table size_hist as select now() as select_time, size, size_pretty, cluster_name, inet_server_addr() as ip, inet_server_port() as port from (select sum(pg_database_size(datname)) as size, pg_size_pretty(sum(pg_database_size(datname))) as size_pretty from pg_database) as db, (select setting as cluster_name from pg_settings where name='cluster_name') as st;
CREATE INDEX ON size_hist (select_time);
insert into size_hist(select_time,size,size_pretty,cluster_name,ip,port) select now() as select_time, size, size_pretty, cluster_name, inet_server_addr() as ip, inet_server_port() as port from (select sum(pg_database_size(datname)) as size, pg_size_pretty(sum(pg_database_size(datname))) as size_pretty from pg_database) as db, (select setting as cluster_name from pg_settings where name='cluster_name') as st;
INSERT INTO cron.job (schedule, command, nodename, nodeport, database, username, jobname) VALUES ('* * * * *', 'insert into size_hist(select_time,size,size_pretty,cluster_name,ip,port) select now() as select_time, size, size_pretty, cluster_name, inet_server_addr() as ip, inet_server_port() as port from (select sum(pg_database_size(datname)) as size, pg_size_pretty(sum(pg_database_size(datname))) as size_pretty from pg_database) as db, (select setting as cluster_name from pg_settings where name=''cluster_name'') as st;', '127.0.0.1', 5432, 'postgres', 'postgres', 'history');
truncate table size_hist;
EOF
  echo 
  echo "Create pg5435 instance as copy of pg5432 instance (for logical replication testing)"
  echo
  pg_basebackup -p ${PGPORT} -D /pgdata/13/pg5435 -P -v && chmod -v 700 /pgdata/13/pg5435
  echo
  echo "Stop pg5432 instance"
  echo
  pg_ctl stop -w -D ${PGDATA}
  sleep 1
  echo
  echo "Create cold backup of pg5432 instance"
  cd ${PGDATA}/../ && tar -czf pg${PGPORT}_cold_backup.tar.gz pg${PGPORT} && echo && echo "Cold backup of pg5432 instance: OK"
  echo
  echo "Add parameters for archive WAL to ${PGDATA}/postgresql.conf"
  echo "archive_mode = on
archive_command = 'test ! -f /pgdata/archivewal/from_pg5432/%f && cp %p /pgdata/archivewal/from_pg5432/%f'
archive_timeout = 900" >> ${PGDATA}/postgresql.conf
  echo
  echo Start pg5432 instance
  echo
  pg_ctl start -D ${PGDATA} -l /home/postgres/pg${PGPORT}.log
  echo "Add parameters (port, cluster_name) to /pgdata/13/pg5435/postgresql.conf"
  echo "port = 5435
cluster_name = 'pg5435'" >> /pgdata/13/pg5435/postgresql.conf
  echo
  echo Start pg5435 instance
  echo
  pg_ctl start -D /pgdata/13/pg5435 -l /home/postgres/pg5435.log
  echo
  echo "Update cron.job table (set nodeport=5435) for pg5435 instance"
  echo
  psql -p 5435 -c "update cron.job set nodeport='5435';"
  echo
  echo "Create pg5433 and pg5434 instances as copies of pg5432 instance (for physical replication testing)"
  echo
  pg_basebackup -p ${PGPORT} -D /pgdata/13/pg5433 -P -v && chmod -v 700 /pgdata/13/pg5433
  echo
  pg_basebackup -p ${PGPORT} -D /pgdata/13/pg5434 -P -v && chmod -v 700 /pgdata/13/pg5434
  echo
  echo "Add parameters (port, cluster_name, primary_conninfo, restore_command) to /pgdata/13/pg5433/postgresql.conf"
  echo "port = 5433
cluster_name = 'pg5433'
primary_conninfo = 'port=5432 user=postgres options=''-c wal_sender_timeout=5000'''
restore_command = 'cp /pgdata/archivewal/from_pg5432/%f %p'" >> /pgdata/13/pg5433/postgresql.conf
  echo
  echo "Add parameters (port, cluster_name, restore_command) to /pgdata/13/pg5434/postgresql.conf"
  echo "port = 5434
cluster_name = 'pg5434'
restore_command = 'cp /pgdata/archivewal/from_pg5432/%f %p'" >> /pgdata/13/pg5434/postgresql.conf
  echo
  echo Add standby.signal file for pg5433 and pg5434 instances
  echo
  touch /pgdata/13/pg5433/standby.signal
  touch /pgdata/13/pg5434/standby.signal
  ls -l /pgdata/13/pg5433/standby.signal
  ls -l /pgdata/13/pg5434/standby.signal
  echo
  echo Start pg5433 and pg5434 instances
  echo
  pg_ctl start -D /pgdata/13/pg5433 -l /home/postgres/pg5433.log
  echo
  pg_ctl start -D /pgdata/13/pg5434 -l /home/postgres/pg5434.log
  echo
else
  echo
  echo ${PGDATA} directory is not empty
  echo
  echo Starting instances
  echo
  pg_ctl restart -D ${PGDATA} -l /home/postgres/pg${PGPORT}.log
  echo
  pg_ctl restart -D /pgdata/13/pg5433 -l /home/postgres/pg5433.log
  echo
  pg_ctl restart -D /pgdata/13/pg5434 -l /home/postgres/pg5434.log
  echo
  pg_ctl restart -D /pgdata/13/pg5435 -l /home/postgres/pg5435.log
  echo
fi

date
echo "Container is running"
while true; do sleep 36525d ; done
