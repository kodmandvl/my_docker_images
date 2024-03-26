#!/bin/sh

source /home/postgres/postgres16.env

if [ ! -d "${PGDATA}" ]
then
  echo
  echo ${PGDATA} directory does not exist
  echo
  echo Create ${PGDATA} directory
  mkdir -p ${PGDATA}
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
  mkdir -p ${PGDATA}/log
  echo "# Add parameters to postgresql.conf file:
listen_addresses = '*'
port = 5432
max_connections = 256
superuser_reserved_connections = 5
password_encryption = 'scram-sha-256'
" >> ${PGDATA}/postgresql.conf
  echo "# New pg_hba.conf file:
local   all             all                                     peer
host    all             all             0.0.0.0/0               scram-sha-256
local   replication     all                                     peer
host    replication     all             0.0.0.0/0               scram-sha-256
" > ${PGDATA}/pg_hba.conf
else
  echo
  echo ${PGDATA} directory is not empty
fi

echo
echo Starting Postgres database instance
echo
postgres -D ${PGDATA}

echo
echo "Postgres database instance is stopped or restarted, wait 15 minutes before stop container..."
sleep 900
