# README

# Download config

```shell
cat << EOF | sudo tee -a /etc/sysctl.conf

vm.overcommit_memory = 1
EOF

# fetch config file 
mkdir -p ./conf

curl -L https://download.redis.io/redis-stable/redis.conf -o ./conf/redis.conf

cat << EOF | tee -a ./conf/redis.conf
bind 0.0.0.0
appendonly yes
aclfile /etc/redis/redis.acl
EOF

## create acl
cat << EOF | tee -a ./conf/redis.acl
user redis on >redis ~* &* +@all
EOF
```

# Run

```bash
docker compose up -d 
```