#!/bin/sh

source /home/postgres/postgres13.env

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
  echo Init database instance
  echo
  initdb -k -D ${PGDATA} --locale=en_US.UTF-8
  mkdir -pv ${PGDATA}/log
  mkdir -pv ${PGDATA}/env && cp -av /home/postgres/postgres13.env ${PGDATA}/env/
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
  chmod 0600 ./*.key && chmod 0644 ./*.crt && echo && echo "Certificates: OK"
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
ssl_cert_file = '${PGDATA}/ssl/server.crt'
ssl_key_file = '${PGDATA}/ssl/server.key'
ssl_ca_file = '${PGDATA}/ssl/root.crt'
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
cluster_name = 'pg13'
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
  echo "Start Postgres database instance"
  echo
  pg_ctl start -D ${PGDATA} -l /home/postgres/pg13.log
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
  echo "Stop Postgres database instance"
  echo
  pg_ctl stop -w -D ${PGDATA}
  sleep 1
  echo
  echo "Create cold backup"
  cd ${PGDATA}/../ && tar -czf data.tar.gz data && echo && echo "Cold backup: OK"
else
  echo
  echo ${PGDATA} directory is not empty
fi

echo
echo Starting Postgres database instance
echo
postgres -D ${PGDATA}

echo
date
echo "Postgres database instance is stopped or restarted, wait 15 minutes before stop container..."
sleep 900
