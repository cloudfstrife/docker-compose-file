#!/bin/bash

NODES=8
IP_ADDRESS=192.168.20.200
SUBNET=172.16.0.0/24
REDIS_IMAGE=redis:7.0.11
PASSWD=password

# generate conf
for i in $(seq 1 ${NODES});                                 \
do                                                          \
mkdir -p ./node-${i}/conf                                               
cat << EOF | tee -a ./node-${i}/conf/redis.conf >/dev/null
port `expr 6379 + ${i}`
masterauth ${PASSWD}
requirepass ${PASSWD}
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip ${IP_ADDRESS}
cluster-announce-port `expr 6379 + ${i}`
cluster-announce-bus-port `expr 16379 + ${i}`
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF
done

# generate docker-compose.yml
cat << EOF | tee -a docker-compose.yml > /dev/null
version: "3.9"
services:
EOF

for i in $(seq 1 ${NODES});                                 \
do                                                          \
cat << EOF | tee -a docker-compose.yml > /dev/null
  node-${i}:
    image: ${REDIS_IMAGE}
    environment:
      TZ: Asia/Shanghai
    ports:
      - "`expr 6379 + ${i}`:`expr 6379 + ${i}`"
      - "`expr 16379 + ${i}`:`expr 16379 + ${i}`"
    volumes:
      - ./node-${i}/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - ./node-${i}/data:/data
      - ./node-${i}/logs:/logs
    command: 
      - redis-server
      - /usr/local/etc/redis/redis.conf

EOF
done

cat << EOF | tee -a docker-compose.yml > /dev/null
networks:
  proxy:
    ipam:
      config:
      - subnet: ${SUBNET}
EOF

printf "start nodes\n"
printf "# --------------------------------------------------------------------------\n"
printf "docker compose up -d\n\n"

printf "create cluster\n"
printf "# --------------------------------------------------------------------------\n"
printf "docker compose exec node-1 redis-cli -a %s --cluster create %s\n" ${PASSWD} "\\"
for i in $(seq 1 ${NODES});do
printf "%s:%d %s\n" ${IP_ADDRESS} `expr 6379 + ${i}` "\\"
done
printf "%s %d\n\n" "--cluster-replicas" 1

printf "connect node\n"
printf "# --------------------------------------------------------------------------\n"
for i in $(seq 1 ${NODES});do
printf "docker compose exec node-%d redis-cli -a %s -p %d \n\n" ${i} ${PASSWD} `expr 6379 + ${i}`
done

