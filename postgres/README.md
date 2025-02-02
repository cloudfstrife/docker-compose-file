# README

## Customization

### gen config 

```bash
mkdir -p config
docker run -i --rm postgres:17.2 cat /usr/share/postgresql/postgresql.conf.sample > ./config/postgresql.conf

# 时区
sed -i "s|#timezone = 'GMT'|timezone = 'Asia/Shanghai'|g" config/postgresql.conf
sed -i "s|#log_timezone = 'GMT'|log_timezone = 'Asia/Shanghai'|g" config/postgresql.conf

# 启用分区表剪枝特征
sed -i "s|#enable_partition_pruning|enable_partition_pruning|g" config/postgresql.conf

## max_connections 最大连接数
sed -i "s|#max_connections = [0-9]*|max_connections = 500|g" config/postgresql.conf

# 性能优化

## shared_buffers 建议 25％ 的物理内存
sed -i "s|^#shared_buffers = [0-9]*[K,M,G,T]B|shared_buffers = 4GB|g" config/postgresql.conf
## effective_cache_size 建议 50%-75% 的物理内存
sed -i "s|^#effective_cache_size = [0-9]*[K,M,G,T]B|effective_cache_size = 64GB|g" config/postgresql.conf

## wal_buffers
sed -i "s|^#wal_buffers|wal_buffers|g" config/postgresql.conf
## synchronous_commit
sed -i "s|^#synchronous_commit|synchronous_commit|g" config/postgresql.conf
```

### run

```bash
docker compose up -d
```