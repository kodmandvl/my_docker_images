##### CLONED FROM CLOUD NATIVE PG (https://github.com/cloudnative-pg/postgres-containers.git) AND CHANGED BY ME #####
#####################################################################################################################
# docker login
# docker build -t kodmandvl/cnpg:16 .
# docker push kodmandvl/cnpg:16
# docker pull kodmandvl/cnpg:16
# docker tag kodmandvl/cnpg:16 kodmandvl/cnpg:latest
# docker push kodmandvl/cnpg:latest
# docker pull kodmandvl/cnpg:latest
# docker tag kodmandvl/cnpg:16 kodmandvl/cnpg:16.2
# docker push kodmandvl/cnpg:16.2
# docker pull kodmandvl/cnpg:16.2
# docker images | grep kodmandvl.*cnpg
## Example:
# docker run -d -p 5432:5432 --name mycnpg16 -h mycnpg16 -e POSTGRES_PASSWORD=password kodmandvl/cnpg:16
## Reset password for postgres user (if you need):
# docker exec -it mycnpg16 /bin/bash /var/lib/postgresql/set_password.sh
# psql postgres://postgres@127.0.0.1:5432/postgres -c "select inet_server_addr(), inet_server_port(), version(), now();"
# docker logs mycnpg16 -f
# docker exec -it mycnpg16 /bin/bash
#####################################################################################################################

# vim:set ft=dockerfile:
#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM postgres:16.2-bullseye

# Do not split the description, otherwise we will see a blank space in the labels
LABEL name="PostgreSQL Container Images" \
      vendor="The CloudNativePG Contributors" \
      version="${PG_VERSION}" \
      release="10" \
      summary="PostgreSQL Container images." \
      description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres 16.2-bullseye."

LABEL org.opencontainers.image.description="This Docker image contains PostgreSQL and Barman Cloud based on Postgres 16.2-bullseye."

COPY requirements.txt /

# Install additional extensions
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pgaudit" \
		"postgresql-${PG_MAJOR}-pgvector" \
		"postgresql-${PG_MAJOR}-pg-failover-slots" \
	; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install barman-cloud
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install --upgrade pip; \
# TODO: Remove --no-deps once https://github.com/pypa/pip/issues/9644 is solved
	pip3 install --no-deps -r requirements.txt; \
	rm -rf /var/lib/apt/lists/*;

# Install additional tools and extensions
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pg-wait-sampling" \
		"postgresql-${PG_MAJOR}-pg-stat-kcache" \
		"postgresql-${PG_MAJOR}-cron" \
		openssh-client grep gawk sed bc mc net-tools telnet sudo \
		lsof tzdata wget curl man zip unzip binutils psmisc nano vim jq \
		tar bzip2 gzip p7zip* \
		openssl bash-completion passwd \
		findutils procps lsof \
		libpq5 pgbadger pgbouncer \
		diffutils gpg \
	; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Install pg_profile extension:
RUN su -l postgres -c "wget https://github.com/zubkov-andrei/pg_profile/releases/download/4.3/pg_profile--4.3.tar.gz" && \
	tar xzvf /var/lib/postgresql/pg_profile--4.3.tar.gz --directory /usr/share/postgresql/16/extension ;

# Install pg_probackup:
RUN wget -qO - https://repo.postgrespro.ru/pg_probackup/keys/GPG-KEY-PG-PROBACKUP | \
	tee /etc/apt/trusted.gpg.d/pg_probackup.asc ;
COPY pg_probackup.list /etc/apt/sources.list.d/pg_probackup.list
RUN apt-get update ; \
	apt-get install pg-probackup-16 \
	; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;

# Sudo for postgres user:
COPY sudoers /etc/sudoers

# Copy files:
COPY psqlrc /var/lib/postgresql/.psqlrc
COPY postgres16.env /var/lib/postgresql/.bashrc
COPY postgres16.env /var/lib/postgresql/.profile
COPY set_password.sh /var/lib/postgresql/set_password.sh

# Change rights and ownership:
RUN chown -v postgres:postgres /var/lib/postgresql/.bashrc && \
	chown -v postgres:postgres /var/lib/postgresql/.profile && \
	chown -v postgres:postgres /var/lib/postgresql/.psqlrc && \
	chown -v postgres:postgres /var/lib/postgresql/set_password.sh && \
	chmod -v 750 /var/lib/postgresql/set_password.sh ;

# Change the uid of postgres to 26
RUN usermod -u 26 postgres
USER 26
