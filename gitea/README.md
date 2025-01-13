# README

## init

### gen PostgreSQL config 

```bash
mkdir -p postgres/config
docker run -i --rm postgres:17.2-alpine cat /usr/share/postgresql/postgresql.conf.sample > ./postgres/config/postgresql.conf
```

### run

```bash
docker compose up -d
```

### view

[http://127.0.0.1:3000](http://127.0.0.1:3000)
