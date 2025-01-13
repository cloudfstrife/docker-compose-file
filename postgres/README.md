# README

## Customization

### gen config 

```bash
mkdir -p config
docker run -i --rm postgres:17.2 cat /usr/share/postgresql/postgresql.conf.sample > ./config/postgresql.conf
```

### run

```bash
docker compose up -d
```