# build.sh

build.sh 用于生成 redis cluster 的 docker-compose.yml 文件和 node 目录结构

用法：
```console
# 生成 配置文件 与 `docker-compose.yml`
./build.sh dc

# 生成创建集群的指令
./build.sh show
```

# 环境变量说明
```console
# 每个节点的实例数量
INS_PER_NODE=2
# 节点列表
NODE_LIST="10.0.0.10 10.0.0.11 10.0.0.12"
# 镜像版本
REDIS_IMAGE=redis:7.0.11
# 密码
PASSWD=password
```
