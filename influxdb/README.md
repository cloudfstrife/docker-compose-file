## 生成 server 配置

```text
docker run --rm influxdb:2.7.4 influxd print-config > config.yml
```

## 创建组织

```text
docker compose exec influxdb influx org create \
  --host http://localhost:8086 \
  --name <INFLUXDB_ORG_NAME> \
  --description <INFLUXDB_ORG_DESCRIPTION>
```

## 创建用户

```text
docker compose exec influxdb influx user create \
  --host http://localhost:8086 \
  --org <INFLUXDB_ORG_NAME> \
  --name <INFLUXDB_USER_NAME> \
  --password <INFLUXDB_PASSWORD>
```

## 创建 All-Access API token

```text
docker compose exec influxdb influx auth create \
  --host http://localhost:8086 \
  --all-access \
  --user <INFLUXDB_USER_NAME> \
  --org <INFLUXDB_ORG_NAME>
```

# 创建配置

```text
docker compose exec influxdb influx config create \
  --host-url http://localhost:8086 \
  --config-name <INFLUXDB_CONFIG_NAME> \
  --org <INFLUXDB_ORG_NAME> \
  --token <INFLUXDB_API_TOKEN> \
  --active
```

# 创建 bucket

```text
docker compose exec influxdb influx bucket create \
  --host-url http://localhost:8086 \
  --org <INFLUXDB_ORG_NAME> \
  --description <INFLUXDB_BUCKET_DESCRIPTION> \
  --name <INFLUXDB_BUCKET_NAME>
```