# Подготовка

Для выполнения данного примера нам понадобится Docker или Podman (тестировалось на Docker-е) 

Скачиваем образ: 

```bash
docker pull kodmandvl/mypostgres16:latest
```

Запускаем контейнер: 

```bash
docker run -d --name pg -h pg  kodmandvl/mypostgres16:latest
docker ps
```

Контейнер (по замыслу автора, т.е. меня) будет работать, пока не остановится/перезапустится инстанс PostgreSQL и плюс еще 15 минут. 

Заходим в контейнер: 

```bash
docker exec -it pg /bin/bash
```

В контейнере у нас работает инстанс PostgreSQL: 

```bash
ps -ef | grep postgres.*[-]D
```

Для дальнейших мероприятий добавим параметр в файл конфигурации postgresql.conf: 

```bash
echo "wal_level = 'logical'
" >> ${PGDATA}/postgresql.conf
exit
```

Перезапустим контейнер и перезайдем в него: 

```bash
docker stop pg
docker start pg
docker ps
docker exec -it pg psql -c "show wal_level;"
docker exec -it pg /bin/bash
```

# Логическая репликация 

Создадим и запустим еще один инстанс для показа логической репликации: 

```bash
# Инициализируем:
export PGDATA=/pgdata/16/logical
initdb -k -D ${PGDATA} --locale=en_US.UTF-8
echo "# Add parameters to postgresql.conf file:
listen_addresses = '*'
port = 5433
wal_level = 'logical'
" >> ${PGDATA}/postgresql.conf
echo "# New pg_hba.conf file:
local   all             all                                     peer
host    all             all             0.0.0.0/0               scram-sha-256
local   replication     all                                     peer
host    replication     all             0.0.0.0/0               scram-sha-256
" > ${PGDATA}/pg_hba.conf
# Запускаем:
pg_ctl -D ${PGDATA} -l ~/logical.log start -w
# Инстансы:
ps -ef | grep postgres.*[-]D
```

Создадим табличку в обоих инстасах и добавим несколько строк: 

```bash
psql -p 5432 -c "create table public.sum_db_size_hist as select now() as select_time, port, 'primary' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5432 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'primary' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5432 -c "select * from public.sum_db_size_hist order by select_time desc;"
# Повторить несколько раз (вставка строки и выборка):
psql -p 5432 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'primary' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5432 -c "select * from public.sum_db_size_hist order by select_time desc;"

```

Аналогично для второго инстанса: 

```bash
psql -p 5433 -c "create table public.sum_db_size_hist as select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "select * from public.sum_db_size_hist order by select_time desc;"
# Повторить несколько раз (вставка строки и выборка):
psql -p 5433 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "select * from public.sum_db_size_hist order by select_time desc;"

```

Параметр wal_level у нас должен быть logical для нашей демонстрации (выше мы его выставили): 

```bash
psql -p 5432 -c "show wal_level;"
psql -p 5433 -c "show wal_level;"
```

Создаем публикацию и подписку 

```bash
# Создадим публикацию для нашей таблицы в первом инстансе: 
psql -p 5432 -c "CREATE PUBLICATION pub_from_5432 FOR TABLE public.sum_db_size_hist;"
psql -p 5432 -c "select * from pg_publication;"
# На втором инстансе подписываемся на публикацию.
# Забегая вперед, отметим, что, чтобы инстанс не принимал те изменения, которые сам ранее отправил, нам нужна опция origin:
psql -p 5433 -c "CREATE SUBSCRIPTION sub_for_5432 CONNECTION 'port=5432 user=postgres dbname=postgres' PUBLICATION pub_from_5432 WITH (copy_data = true, origin = none);"
# Узнать подробности и статистику по репликации и подписке:
psql -p 5432 -c "select * from pg_stat_replication;"
psql -p 5432 -c "select * from pg_replication_slots;"
psql -p 5433 -c "select * from pg_subscription;"
psql -p 5433 -c "select * from pg_stat_subscription;"
# Данные в первом инстансе:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
# Данные во втором инстансе:
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
# Видим данные из первого инстанса во втором?
# Далее попробуем, наконец, создать подписку в обратную сторону и узнать, правда ли возможна двунаправленная репликация в PostgreSQL 16?
# Создаем публикацию теперь уже на втором инстансе:
psql -p 5433 -c "CREATE PUBLICATION pub_from_5433 FOR TABLE public.sum_db_size_hist;"
psql -p 5433 -c "select * from pg_publication;"
# На исходном (первом) инстансе подписываемся на публикацию.
# Здесь нам обязательно нужно, чтобы инстанс не принимал те изменения, которые сам ранее отправил.
# Для этого нам поможет опция origin:
psql -p 5432 -c "CREATE SUBSCRIPTION sub_for_5433 CONNECTION 'port=5433 user=postgres dbname=postgres' PUBLICATION pub_from_5433 WITH (copy_data = true, origin = none);"
# Данные в инстансах:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
```

И какие же данные в инстансах теперь? Как вы думаете, почему? (Подсказка: copy_data = true, origin = none) 

[См. подробнее об опции origin при создании подписки](https://postgrespro.ru/docs/postgresql/16/sql-createsubscription#SQL-CREATESUBSCRIPTION-WITH-ORIGIN) 

# Задание со *

Давайте теперь подобавляем, поудаляем, поизменяем строки, чтобы убедиться, что наша репликация (двунаправленная, на минуточку!) действительно работает: 

```bash
# Какая-то новая строка в таблицу на исходном инстансе:
psql -p 5432 -c "insert into public.sum_db_size_hist (select_time, port, cluster_name, sum_db_size) values (null, 7777, 'alien1', '2 TB');"
# Какая-то новая строка в таблицу на втором инстансе:
psql -p 5433 -c "insert into public.sum_db_size_hist (select_time, port, cluster_name, sum_db_size) values ('1970-01-01 00:00:00', 8888, 'alien2', '7 GB');"
# Данные в инстансах:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Обновление:
psql -p 5433 -c "update public.sum_db_size_hist set cluster_name='1' where port='5432';"
psql -p 5432 -c "update public.sum_db_size_hist set cluster_name='2' where port='5433';"
# Данные в инстансах:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Удаление строк:
psql -p 5433 -c "delete from public.sum_db_size_hist where port='5432';"
psql -p 5432 -c "delete from public.sum_db_size_hist where port='5433';"
# Данные в инстансах:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Еще попробуем TRUNCATE:
psql -p 5432 -c "truncate table sum_db_size_hist ;"
# Данные в инстансах:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

```

Удалась ли репликация добавленных, измененных и удалённых строк? Почему? 

Среплицировались ли результаты команды TRUNCATE? 

Выполним ALTER TABLE и попробуем еще раз добавить, изменить, удалить строки: 

```bash
psql -p 5432 -c "ALTER TABLE sum_db_size_hist REPLICA IDENTITY FULL;"
psql -p 5433 -c "ALTER TABLE sum_db_size_hist REPLICA IDENTITY FULL;"

# Insert:
psql -p 5432 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'primary' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5432 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'primary' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5433 -c "insert into public.sum_db_size_hist select now() as select_time, port, 'logical' as cluster_name, sum_db_size from (select pg_size_pretty(sum(pg_database_size(datname))) as sum_db_size from pg_database) as db, (select setting as port from pg_settings where name='port') as st;"
psql -p 5432 -c "insert into public.sum_db_size_hist (select_time, port, cluster_name, sum_db_size) values (null, 7777, 'alien1', '2 TB');"
psql -p 5433 -c "insert into public.sum_db_size_hist (select_time, port, cluster_name, sum_db_size) values ('1970-01-01 00:00:00', 8888, 'alien2', '7 GB');"

# Select:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Update:
psql -p 5433 -c "update public.sum_db_size_hist set cluster_name='1' where port='5432';"
psql -p 5432 -c "update public.sum_db_size_hist set cluster_name='2' where port='5433';"

# Select:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Delete:
psql -p 5433 -c "delete from public.sum_db_size_hist where port='5432';"
psql -p 5432 -c "delete from public.sum_db_size_hist where port='5433';"

# Select:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

# Truncate:
psql -p 5432 -c "truncate table sum_db_size_hist ;"

# Select:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"

```

Как теперь изменились результаты? Почему? 

# Домашнее задание: физическая репликация

Теперь в дополнение к двум имеющимся инстансам, объединенным двунаправленной логической репликацией таблицы sum_db_size_hist, добавьте еще один, который для нашего первого экземпляра будет являться физической синхронной потоковой репликой (PGDATA для нового инстанса должна быть /pgdata/16/physical) 

Подсказка: используйте pg_basebackup, сигнальный файл, параметры postgresql.conf 

## Пример возможного варианта выполнения ДЗ (решебник)

Примечание: для простоты учебного примера особенности настройки с учетом архивации WAL и restore_command здесь опущены. 

* Снятие бэкапа для нашей будущей физической реплики (далее команды bash там же, внутри контейнера): 

```bash
pg_basebackup -v -D /pgdata/16/physical 
```

* Добавление сигнального файла: 

```bash
touch /pgdata/16/physical/standby.signal
```

* Зададим пароль для postgres на нашем исходном инстансе с помощью команды \password и пропишем для учебного примера в ~/.pgpass в формате *:*:*:postgres:password

* Добавление параметра conninfo в postgresql.conf для нашей будущей реплики и другого порта 

```bash
echo "port = 5434" >> /pgdata/16/physical/postgresql.conf
echo "primary_conninfo = 'host=127.0.0.1 port=5432 user=postgres options=''-c wal_sender_timeout=5000'''" >> /pgdata/16/physical/postgresql.conf
```

* Запустим реплику: 

```bash
pg_ctl start -D /pgdata/16/physical
```

* Посмотрим слоты репликации на исходном инстансе, а также данные на исходном инстансе и новой реплике (перед этим добавим данных, как в примерах выше было): 

```bash
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5434 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5432 -c "select pg_is_in_recovery();"
psql -p 5434 -c "select pg_is_in_recovery();"
psql -p 5432 -c "select * from pg_stat_replication;"
```

* А для того, чтобы наша потоковая репликация стала синхронной, нужно убедиться, что параметр synchronous_commit на нашем исходном инстансе был включен, а также параметр synchronous_standby_names был не пустым и указывал на процесс, получающий данные реплику, например, synchronous_standby_names = 'walreceiver'. 

Проверим synchronous_commit, добавим synchronous_standby_names, перезапустим контейнер, добавим еще данных, посмотрим на данные и на pg_stat_replication теперь: 

```bash
psql -p 5432 -c "show synchronous_commit;"
echo "synchronous_standby_names = 'walreceiver'" >> /pgdata/16/data/postgresql.conf
exit
# Уже за пределами контейнера: 
docker stop pg
docker start pg
docker exec -it pg /bin/bash
# Далее снова в контейнере: 
pg_ctl start -D /pgdata/16/physical -l ~/physical.log
pg_ctl start -D /pgdata/16/logical -l ~/logical.log
ps -ef | grep postgres.*[-]D
netstat -anp -Ainet -A inet6
# Еще докинем данных, как в примерах выше было и смотрим:
psql -p 5432 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5433 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5434 -c "select count(*), min(select_time), max(select_time), port, cluster_name from public.sum_db_size_hist group by port, cluster_name;"
psql -p 5432 -c "select pg_is_in_recovery();"
psql -p 5434 -c "select pg_is_in_recovery();"
psql -p 5432 -c "select * from pg_stat_replication;"

```

Обратите внимание на sync_state для walreceiver. 

## ДЗ со *

Как изменился бы sync_state в выводе pg_stat_replication, если бы мы прописали в postgresql.conf для нашего лидера: 

```
synchronous_standby_names = 'ANY 2 (walreceiver, sub_for_5432)'
```

Ответ: quorum (для обоих) 

