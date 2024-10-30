# elasticsearch single node

## 内核参数

```bash 
cat << EOF | sudo tee -a /etc/sysctl.conf
vm.max_map_count=524288
fs.file-max=131072
EOF
```

## 创建目录
```bash
mkdir -p ./elasticsearch/{data,plugins,logs}
mkdir -p ./elasticsearch/config/certs
```

## 创建 CA 证书
```bash
docker run -it --rm \
-v ./elasticsearch/config/certs:/usr/share/elasticsearch/config/certs \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-certutil ca --out config/certs/elastic-ca.p12 --pass "elasticsearch"
```

## 创建证书
```bash
docker run -it --rm \
-v ./elasticsearch/config/certs:/usr/share/elasticsearch/config/certs \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-certutil cert --silent --ca config/certs/elastic-ca.p12 --out config/certs/elastic-certificates.p12 --ca-pass "elasticsearch" --pass "elasticsearch"
```

## 配置证书文件权限
```bash
chown -R 1000:0 ./elasticsearch/{data,logs} ./elasticsearch/config/certs
```

## 生成加密的 keystore 文件
```bash
docker run -it --rm \
-v ./elasticsearch/config:/usr/share/elasticsearch/config \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-keystore create -p
```

## 证书密码配置项添加到 keystore 文件

### keystore.secure_password

> 此处输入证书密码

```bash
docker run -it --rm \
-v ./elasticsearch/config:/usr/share/elasticsearch/config \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password
```

### truststore.secure_password

> 此处输入证书密码

```bash
docker run -it --rm \
-v ./elasticsearch/config:/usr/share/elasticsearch/config \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
```

## elasticsearch.keystore 
```bash
docker run -it --rm \
-v ./elasticsearch/config:/usr/share/elasticsearch/config \
docker.elastic.co/elasticsearch/elasticsearch:8.15.3 \
bin/elasticsearch-keystore list
```

## 生成配置

### elasticsearch.yml
```bash
cat << EOF | tee -a ./elasticsearch/config/elasticsearch.yml
# 基本配置
cluster.name: es-cluster
discovery.type: single-node
network.host: 0.0.0.0
http.port: 9200

# 启用 xpack 及 TLS
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true

# 证书配置
xpack.security.transport.ssl.keystore.type: PKCS12
xpack.security.transport.ssl.truststore.type: PKCS12
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: certs/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: certs/elastic-certificates.p12

# 其他配置

## 禁用 geoip
ingest.geoip.downloader.enabled: false
EOF
```

### kibana

```bash 
mkdir -p ./kibana/config

cat << EOF | tee -a ./kibana/config/kibana.yml
server.name: kibana
server.host: "0.0.0.0"
server.publicBaseUrl: "http://xxx.xxx.xxx.xxx:5601"
elasticsearch.hosts: [ "http://elasticsearch:9200" ]
elasticsearch.ssl.verificationMode: none
elasticsearch.username: testing
elasticsearch.password: password
xpack.monitoring.ui.container.elasticsearch.enabled: true
i18n.locale: "zh-CN"
EOF 
```

### docker-compose.yml
```bash
cat << EOF | tee -a docker-compose.yml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.15.3
    ports:
      - 9200:9200
      - 9300:9300
    volumes:
      - ./elasticsearch/data:/usr/share/elasticsearch/data
      - ./elasticsearch/plugins:/usr/share/elasticsearch/plugins
      - ./elasticsearch/logs:/usr/share/elasticsearch/logs
      - ./elasticsearch/config/certs/:/usr/share/elasticsearch/config/certs
      - ./elasticsearch/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./elasticsearch/config/elasticsearch.keystore:/usr/share/elasticsearch/config/elasticsearch.keystore
    environment:
      TZ: Asia/Shanghai
      ES_JAVA_OPTS: "-Xms2048m -Xmx2048m"
      KEYSTORE_PASSWORD: keystore_password
    ulimits:
      nproc: 65535
      memlock:
        soft: -1
        hard: -1
    restart: on-failure
  kibana:
    image: kibana:8.15.3
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ./kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml
    ports:
      - "5601:5601"
    restart: on-failure
EOF
```


# 启动
```bash
docker compose up -d 
```

# 初始化保留用户密码
```bash
docker compose exec elasticsearch bin/elasticsearch-setup-passwords auto
```

# 创建自定义用户
```bash
docker compose exec elasticsearch bin/elasticsearch-users useradd testing -p password -r superuser
```
