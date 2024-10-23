#!/bin/bash

set -e 
set -u

FOLDER=`cd $(dirname $0);pwd`

# node list
NODE_LIST=( "10.0.0.1:6380" "10.0.0.1:6382" "10.0.0.1:6384" "10.0.0.1:6386" "10.0.0.1:6388" "10.0.0.1:6390")
REDIS_IMAGE=redis:7.2.5
PASSWD=password

RED="\u001b[31m"
RESET="\u001b[0m"

# generate conf
generate(){
  for NODE in ${NODE_LIST[@]}
  do
    HOST=${NODE%%:*}
    PORT=${NODE##*:}
 
    mkdir -p ${FOLDER}/${HOST}/node-${PORT}/conf
    cat << EOF | tee -a ${FOLDER}/${HOST}/node-${PORT}/conf/redis.conf >/dev/null
port ${PORT}
masterauth ${PASSWD}
requirepass ${PASSWD}
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip ${HOST}
cluster-announce-port ${PORT}
cluster-announce-bus-port `expr ${PORT} + 10000`
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF

    if [ ! -f "${FOLDER}/${HOST}/docker-compose.yaml" ]
    then
      cat << EOF | tee -a ${FOLDER}/${HOST}/docker-compose.yaml > /dev/null
services:
EOF
    fi

    cat << EOF | tee -a ${FOLDER}/${HOST}/docker-compose.yaml > /dev/null
  node-${PORT}:
    image: ${REDIS_IMAGE}
    environment:
      TZ: Asia/Shanghai
    ports:
      - ${PORT}:${PORT}
      - `expr ${PORT} + 10000`:`expr ${PORT} + 10000`
    volumes:
      - ./node-${PORT}/conf/redis.conf:/usr/local/etc/redis/redis.conf
      - ./node-${PORT}/data:/data
      - ./node-${PORT}/logs:/logs
    command: 
      - redis-server
      - /usr/local/etc/redis/redis.conf
EOF
  done
}

show(){
  printf "create cluster\n"
  printf "${RED}--------------------------------------------------------------------------------${RESET}\n"

  FIRST_NODE_PORT=${NODE_LIST[0]##*:}
  printf "docker compose exec node-%d redis-cli -a %s --cluster create %s\n" ${FIRST_NODE_PORT} ${PASSWD} "\\"
  for node in ${NODE_LIST[@]}
  do
    printf "%s %s\n" ${node} "\\"
  done
  printf "%s %d\n\n" "--cluster-replicas" 1

  printf "connect node\n"
  printf "${RED}--------------------------------------------------------------------------------${RESET}\n"

  for NODE in ${NODE_LIST[@]}
  do
    HOST=${NODE%%:*}
    PORT=${NODE##*:}
    printf "%s\n" ${HOST}
    printf "docker compose exec node-%d redis-cli -a %s -p %d \n\n" ${PORT} ${PASSWD} ${PORT}
  done
  
  printf "${RED}--------------------------------------------------------------------------------${RESET}\n"
}

case "$1" in
  "show") show ;;
  "dc") generate ;;
  *) echo "USAGE : $0 [dc|show]"
    exit 1 ;;
esac
