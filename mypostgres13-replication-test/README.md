# Docker Image for PostgreSQL 13 replication testing

## Instances

|cluster_name|data_directory|port|comment|
|:-----------|:-------------|:---|:------|
|pg5432|/pgdata/13/pg5432|5432|Leader instance, in RW mode. It has some extensions and the size_hist table for check activity. It has parameters for archive WAL.|
|pg5433|/pgdata/13/pg5433|5433|Replica instance (for pg5342), in RO mode. It has primary_conninfo and restore_command parameters.|
|pg5434|/pgdata/13/pg5434|5434|Replica instance (for pg5342), in RO mode. It has restore_command parameter.|
|pg5435|/pgdata/13/pg5435|5435|Standalone instance, in RW mode. It has some extensions and the size_hist table for check activity. You can use pg5432 and pg5435 instances to set up and test logical replication between them.|

There are environment files for every instance in /home/postgres directory:

- pg5432.env (default env, added to .bashrc and .bash_profile)
- pg5433.env
- pg5434.env
- pg5435.env

## pg_hba.conf (for all instances)

```conf
hostssl all          postgres 127.0.0.1/32 cert
hostssl replication  postgres 127.0.0.1/32 cert
host    all          all      0.0.0.0/0    scram-sha-256
host    replication  all      0.0.0.0/0    scram-sha-256
```

There are selfsigned certificates on /home/postgres/ssl directory.

## Run container

Example:

```bash
# Example without "-v" option:
docker run -d -p 5432:5432 -p 5433:5433 -p 5434:5434 -p 5435:5435 --name pg13 -h pg13 kodmandvl/postgres:13-replication-test
# Example with "-v" option:
mkdir -p ${HOME}/temp/pg13 && chmod 777 ${HOME}/temp/pg13
docker run -d -p 5432:5432 -p 5433:5433 -p 5434:5434 -p 5435:5435 -v ${HOME}/temp/pg13:/pgdata --name pg13 -h pg13 kodmandvl/postgres:13-replication-test
# See logs:
docker logs pg13 -f
# Run bash on container:
docker exec -it mypg13 /bin/bash
```

## Examples of queries to check status and activity

```bash
# Status of instances:
pg_ctl status -D /pgdata/13/pg5432
pg_ctl status -D /pgdata/13/pg5433
pg_ctl status -D /pgdata/13/pg5434
pg_ctl status -D /pgdata/13/pg5435
# State of replication (from pg5432 to pg5433):
psql -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;' -p 5432
# State of size_hist table (this table is updated on schedule with pg_cron on RW instances):
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5432
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5433
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5434
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5435
# Lag for replicas:
psql -p 5433 -c "SELECT CASE WHEN NOT pg_is_in_recovery() THEN 'LEADER' ELSE 'STANDBY' END AS ROLE, CASE WHEN NOT pg_is_in_recovery() THEN 0 ELSE GREATEST (0, EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))) END AS LAG;"
psql -p 5434 -c "SELECT CASE WHEN NOT pg_is_in_recovery() THEN 'LEADER' ELSE 'STANDBY' END AS ROLE, CASE WHEN NOT pg_is_in_recovery() THEN 0 ELSE GREATEST (0, EXTRACT(EPOCH FROM (now() - 
pg_last_xact_replay_timestamp()))) END AS LAG;"
# Archive WAL:
ls -l /pgdata/archivewal/from_pg5432/
# Switch WAL on pg5432 (if you want quickly check replication to pg5434 with archive WAL):
psql -p 5432 -c "select * from pg_switch_wal();"
ls -l /pgdata/archivewal/from_pg5432/
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5434
psql -p 5434 -c "SELECT CASE WHEN NOT pg_is_in_recovery() THEN 'LEADER' ELSE 'STANDBY' END AS ROLE, CASE WHEN NOT pg_is_in_recovery() THEN 0 ELSE GREATEST (0, EXTRACT(EPOCH FROM (now() - 
pg_last_xact_replay_timestamp()))) END AS LAG;"
```

## What's next

You can study physical and logical replication for PostgreSQL 13 with this image.

### Example 1. You can add a physical replication slot to pg5432 instance and add primary_slot_name parameter to /pgdata/13/pg5433/postgresql.conf

```bash
# Create a slot:
psql -p 5432 -c "select count(*) from pg_replication_slots;"
psql -p 5432 -c "select * from pg_create_physical_replication_slot( 'for_pg5433');"
psql -p 5432 -c 'select slot_name, slot_type, temporary, active, active_pid, wal_status from pg_replication_slots;'
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
# Add parameter primary_slot_name parameter to /pgdata/13/pg5433/postgresql.conf and restart pg5433 instance:
echo "primary_slot_name = 'for_pg5433'" >> /pgdata/13/pg5433/postgresql.conf
pg_ctl restart -w -D /pgdata/13/pg5433 -l /home/postgres/pg5433.log
psql -p 5432 -c 'select slot_name, slot_type, temporary, active, active_pid, wal_status from pg_replication_slots;'
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
```

### Example 2. You cat set synchronous replication from pg5432 to pg5433

```bash
echo "synchronous_commit = 'remote_apply'" >> /pgdata/13/pg5432/postgresql.conf
echo "synchronous_standby_names = 'pg5433'" >> /pgdata/13/pg5432/postgresql.conf
pg_ctl restart -D /pgdata/13/pg5432 -l /home/postgres/pg5432.log
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
```

### Example 3. You can run pg_receivewal for pg5432 and change restore_command on pg5434

```bash
# Create a simple script to run pg_receivewal:
echo 'source /home/postgres/pg5432.env
mkdir -pv /pgdata/receivewal/from_pg5432
pg_receivewal --create-slot --slot=from_pg5432
nohup pg_receivewal -D /pgdata/receivewal/from_pg5432 --slot=from_pg5432 &' > /home/postgres/start_pg_receivewal.sh && chmod -v +x /home/postgres/start_pg_receivewal.sh
# Run script:
/home/postgres/start_pg_receivewal.sh
# Check pg_receivewal:
ls -l /pgdata/receivewal/from_pg5432/
psql -p 5432 -c "select * from pg_switch_wal();"
ls -l /pgdata/receivewal/from_pg5432/
psql -p 5432 -c 'select slot_name, slot_type, temporary, active, active_pid, wal_status from pg_replication_slots;'
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
# Change restore_command on /pgdata/13/pg5434/postgresql.conf and restart pg5434:
echo "restore_command = 'cp /pgdata/receivewal/from_pg5432/%f %p || cp /pgdata/receivewal/from_pg5432/%f.partial %p'" >> /pgdata/13/pg5434/postgresql.conf
pg_ctl restart -D /pgdata/13/pg5434 -l /home/postgres/pg5434.log
psql -p 5434 -c "show restore_command;"
# Check lag on pg5434:
ls -l /pgdata/receivewal/from_pg5432/
psql -p 5432 -c "select * from pg_switch_wal();"
ls -l /pgdata/receivewal/from_pg5432/
psql -p 5432 -c 'select slot_name, slot_type, temporary, active, active_pid, wal_status from pg_replication_slots;'
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5432
psql -c 'select count(*), max(select_time), cluster_name from size_hist group by cluster_name;' -p 5434
psql -p 5434 -c "SELECT CASE WHEN NOT pg_is_in_recovery() THEN 'LEADER' ELSE 'STANDBY' END AS ROLE, CASE WHEN NOT pg_is_in_recovery() THEN 0 ELSE GREATEST (0, EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))) END AS LAG;"
```

### Example 4. You can set up the logical replication from pg5432 to pg5435 (size_hist table)

```bash
# Change wal_level parameter to 'logical' for pg5432 instance:
echo "wal_level = 'logical'" >> /pgdata/13/pg5432/postgresql.conf
# Restart pg5432:
pg_ctl restart -D /pgdata/13/pg5432 -l /home/postgres/pg5432.log
psql -p 5432 -c "show wal_level;"
# Create publication (on pg5432) and subscription (on pg5435):
psql -p 5432 -c "CREATE PUBLICATION pub_from_5432 FOR TABLE public.size_hist;"
psql -p 5432 -c "select * from pg_publication;"
psql -p 5435 -c "CREATE SUBSCRIPTION sub_to_5432 CONNECTION 'port=5432 user=postgres dbname=postgres' PUBLICATION pub_from_5432 WITH (copy_data = true);"
# Check:
psql -p 5432 -c 'select slot_name, slot_type, temporary, active, active_pid, wal_status from pg_replication_slots;'
psql -p 5432 -c 'select pid, application_name, state, sync_priority, sync_state from pg_stat_replication;'
psql -p 5432 -c "select * from pg_publication;"
psql -p 5435 -c "select * from pg_subscription;"
psql -p 5435 -c "select * from pg_stat_subscription;"
psql -c "select count(*), min(select_time), max(select_time), port, cluster_name from size_hist group by port, cluster_name;" -p 5432
psql -c "select count(*), min(select_time), max(select_time), port, cluster_name from size_hist group by port, cluster_name;" -p 5435
# Check replication of TRUNCATE command:
psql -c "truncate table size_hist;" -p 5432
psql -c "select count(*), min(select_time), max(select_time), port, cluster_name from size_hist group by port, cluster_name;" -p 5432
psql -c "select count(*), min(select_time), max(select_time), port, cluster_name from size_hist group by port, cluster_name;" -p 5435
```

### There are many other things you can try and setup:

- manual switchover
- promote of replica(s)
- cascade replication
- and other things

Good luck!
Thank you for using this image!
