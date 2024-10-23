# build.sh

build.sh 用于生成 redis cluster 的 docker-compose.yml 文件和 node 目录结构

用法：
```console
# 生成 配置文件 与 `docker-compose.yml`
bash build.sh dc

# 生成创建集群的指令
bash build.sh show
```

# 环境变量说明
```console
# 节点列表
NODE_LIST=( "10.0.0.1:6380" "10.0.0.1:6382" "10.0.0.1:6384" "10.0.0.1:6386" "10.0.0.1:6388" "10.0.0.1:6390")
# 镜像版本
REDIS_IMAGE=redis:7.0.11
# 密码
PASSWD=password
```
