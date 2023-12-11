## 生成 server 配置

```text
docker run --rm influxdb:2.7.4 influxd print-config > config.yml
```

## 创建 All-Access API token

```text
docker compose exec influxdb influx auth create \
  --all-access \
  --host http://localhost:8086 \
  --org <YOUR_INFLUXDB_ORG_NAME> \
  --token <YOUR_INFLUXDB_OPERATOR_TOKEN>
```

# 创建配置

```text
docker compose exec influxdb influx config create \
  --config-name <YOUR_CONFIG_NAME> \
  --host-url http://localhost:8086 \
  --org <YOUR_INFLUXDB_ORG_NAME> \
  --token <YOUR_INFLUXDB_API_TOKEN>
```

# 创建 bucket

```text
docker compose exec influxdb influx bucket create \
--name <YOUR_INFLUXDB_BUCKET_NAME>
```