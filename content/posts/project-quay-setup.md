---
title: "Project Quay Setup"
date: 2023-03-26T15:28:13-04:00
draft: false
---
With docker deleting open source organizations it might be time to selfhost your own container registry.
Project Quay is the open source version of Redhat Quay, the container registry that powers quay.io. It can be configured as a pull through cache (useful for saving bandwidth). Not a lot of great guides exist for how to setup quay using docker-compose so here it is.
```yaml
---
services:
  quay:
    image: quay.io/projectquay/quay:3.8.4
    # One-time command for running Quay in configurator mode. Disable the
    # following `command` attribute to run the container in operational mode.
    ## command: config secret
    container_name: quay
    ports:
      - 4783:8080
    environment:
      DEBUGLOG: "true"
    depends_on:
      quay-db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - $QUAY_CONFIG:/conf/stack:ro
      - $QUAY_DATASTORE:/datastorage/registry
    networks:
      - quay-net
      - clair-net
    expose:
      - "8080"
      - "8443"
  quay-repomirror:
    image: quay.io/projectquay/quay:3.8.4
    command: repomirror
    container_name: quary-repo-mirror
    environment:
      DEBUGLOG: "true"
    volumes:
      - $QUAY_CONFIG:/conf/stack:ro
      - $QUAY_DATASTORE:/datastorage/registry
    networks:
      - quay-net
      - clair-net
    expose:
      - "8080"
      - "8443"   
  quay-db:
    image: postgres:13-alpine
    environment:
      POSTGRES_USER: quay
      POSTGRES_DB: quay
      POSTGRES_PASSWORD: # don't store your password here if using git, place it elsewhere using a env_file
    volumes:
      - $POSTGRES_QUAY_CONFIG/initdb.d:/docker-entrypoint-initdb.d:ro
      - $POSTGRES_QUAY_DATASTORE:/var/lib/postgresql/data
    networks:
      - quay-net
    expose:
      - "5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U quay -d quay"]
      interval: 10s
      timeout: 10s
      start_period: 10s
      retries: 3
  
  redis:
    image: bitnami/redis:6.2
    environment:
     - REDIS_PASSWORD: # don't store your password here if using git, place it elsewhere using a env_file
    volumes:
      - $REDIS_DATA:/bitnami/redis/data
    networks:
      - quay-net
    expose:
      - "6379"
    healthcheck:
      test: ["CMD-SHELL", "redis-cli PING"]
      interval: 10s
      timeout: 10s
      start_period: 10s
      retries: 3
  
  clair:
    image: quay.io/projectquay/clair:4.6.0
    ports:
     - 6060:6060
    environment:
      CLAIR_MODE: combo
      CLAIR_CONF: /config/config.yaml
    depends_on:
      clair-db:
        condition: service_healthy
    volumes:
      - $CLAIR_CONFIG/config.yaml:/config/config.yaml:ro
    networks:
      - clair-net
      - quay-net
    expose:
      - "6060"
    container_name: clair 
  clair-db:
    image: postgres:13-alpine
    environment:
      POSTGRES_USER: clair
      POSTGRES_PASSWORD:  # don't store your password here if using git, place it elsewhere using a env_file
      POSTGRES_DB: clair
    volumes:
      - $POSTGRES_CLAIR_DATASTORE:/var/lib/postgresql/data
    networks:
      - quay-net
    expose:
      - "5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U clair -d clair"]
      interval: 10s
      timeout: 10s
      start_period: 10s
      retries: 3

networks:
  quay-net:
  clair-net:
```
You will need to create a directory at ` $POSTGRES_QUAY_CONFIG/initdb.d ` and create a file called ` enable-pg_trgm.sh `. In that file paste 
```shell
#!/bin/sh
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE EXTENSION IF NOT EXISTS pg_trgm;
  SELECT * FROM pg_extension;
EOSQL

```
Quay requires the pg_trm module to function. Next create the clair config at ` $CLAIR_CONFIG/config.yaml ` and paste 
```yaml
---
introspection_addr: :6061
http_listen_addr: :6060
log_level: debug

indexer:
  connstring: host=clair-db port=5432 user=clair password=clair dbname=clair sslmode=disable
  scanlock_retry: 10
  layer_scan_concurrency: 5
  migrations: true

matcher:
  connstring: host=clair-db port=5432 user=clair password=clair dbname=clair sslmode=disable
  max_conn_poll: 100
  indexer_addr: "http://clair:6060"
  migrations: true

notifier:
  connstring: host=clair-db port=5432 user=clair password=clair dbname=clair sslmode=disable
  migrations: true
  delivery_interval: 5s
  poll_interval: 15s
  indexer_addr: "http://clair:6060"
  matcher_addr: "http://clair:6060"
  webhook:
    target: "http://quay:8080/secscan/notification"
    callback: "http://clair:6060/api/v1/notifications"
auth:
  psk: 
    key: "REPLACE"
    iss: ["quay"]
```
Next run un-comment the `command: config secret` line in the docker-compose and then run `docker compose up -d`. Pray that everything works( you can take a look with [lazydocker](https://github.com/jesseduffield/lazydocker)). Then navigate to the host at port 4783 and enter the login `quayconfig` and password `secret`. Guide to configure is at https://docs.projectquay.io/config_quay.html#config-using-tool. Enable the `Enable Security Scanning` option and put `http://clair:6060` as the endpoint and click generate PSK and place it in the clair config file at 
```
auth:
  psk: 
    key: "REPLACE"
    iss: ["quay"]
```
When you are done configuring click valid configuration changes, then click download. Place the download tar in `$QUAY_CONFIG` then run `tar xvf quay-config.tar.gz`.
Then run `docker compose restart quay`. Everything should now be working!!
## Comments
{{< chat quaypoject-setup >}}