# README

## 设置内核参数

因为SonarQube使用嵌入式Elasticsearch，确保你的Docker主机配置符合Elasticsearch生产模式要求和文件描述符配置。

```console
echo "vm.max_map_count=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.file-max=131072" | sudo tee -a /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
```

## 创建目录

这里如果不创建目录，SonarQube 启动会因为目录访问权限问题启动失败

```console
mkdir -p ./sonarqube/{data,logs,extensions}
chown -R 1000:1000 ./sonarqube/*
```

## 启动

```console
docker compose up -d 
```

## 访问

```text
http://${SERVER}:9000
```

## 安装 SonarScan

[https://docs.sonarqube.org/10.0/analyzing-source-code/scanners/sonarscanner/](https://docs.sonarqube.org/10.0/analyzing-source-code/scanners/sonarscanner/)


```console
sonar-scanner -Dsonar.projectKey=testing -Dsonar.sources=. -Dsonar.host.url=${SONAR_SERVICE} -Dsonar.token=${SONAR_TOKEN}
```