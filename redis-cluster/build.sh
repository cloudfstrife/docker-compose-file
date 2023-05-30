#!/bin/bash

INS_PER_NODE=2
NODE_LIST="10.0.0.10 10.0.0.11 10.0.0.12"
REDIS_IMAGE=redis:7.0.11
PASSWD=password

# generate conf
generate(){
  for node in ${NODE_LIST};do                                                 \
    mkdir -p ${node}
    for i in $(seq 1 ${INS_PER_NODE});do                                      \
      mkdir -p ./${node}/node-${i}/conf
      cat << EOF | tee -a ./${node}/node-${i}/conf/redis.conf >/dev/null
port `expr 6379 + ${i} - 1`
masterauth ${PASSWD}
requirepass ${PASSWD}
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip ${node}
cluster-announce-port `expr 6379 + ${i} - 1`
cluster-announce-bus-port `expr 16379 + ${i} - 1`
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF
    done

    cat << EOF | tee -a ${node}/docker-compose.yml > /dev/null
version: "3.9"
services:
EOF
    for i in $(seq 1 ${INS_PER_NODE});do                                      \
      cat << EOF | tee -a ${node}/docker-compose.yml > /dev/null
  node-${i}:
    image: ${REDIS_IMAGE}
    environment:
      TZ: Asia/Shanghai
    ports:
      - "`expr 6379 + ${i} - 1`:`expr 6379 + ${i} - 1`"
      - "`expr 16379 + ${i} - 1`:`expr 16379 + ${i} - 1`"
    volumes:
      - ./node-${i}/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - ./node-${i}/data:/data
      - ./node-${i}/logs:/logs
    command: 
      - redis-server
      - /usr/local/etc/redis/redis.conf
EOF
    done
  done
}

show(){
  printf "create cluster\n"
  printf "# --------------------------------------------------------------------------\n"
  printf "docker compose exec node-1 redis-cli -a %s --cluster create %s\n" ${PASSWD} "\\"
  for node in ${NODE_LIST};do                                                                     \
    for i in $(seq 1 ${INS_PER_NODE});do
    printf "%s:%d %s\n" ${node} `expr 6379 + ${i} - 1` "\\"
    done
  done
  printf "%s %d\n\n" "--cluster-replicas" 1

  printf "connect node\n"
  printf "# --------------------------------------------------------------------------\n"
  for i in $(seq 1 ${INS_PER_NODE});do
  printf "docker compose exec node-%d redis-cli -a %s -p %d \n\n" ${i} ${PASSWD} `expr 6379 + ${i} - 1`
  done
}

case "$1" in
  "show") show ;;
  "dc") generate ;;
  *) echo "USAGE : $0 [dc|show]"
    exit 1 ;;
esac
