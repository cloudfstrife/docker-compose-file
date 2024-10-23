#!/bin/bash

set -e
set -u

FOLDER=`cd $(dirname $0);pwd`

# Node
NODE_LIST=( "10.0.0.1:27017" "10.0.0.1:27018" "10.0.0.2:27017" "10.0.0.2:27018" "10.0.0.3:27017" )

# image 
IMAGE=mongodb/mongodb-community-server:7.0.12-ubuntu2204

# mongo environment
MONGODB_INITDB_ROOT_USERNAME=mongo
MONGODB_INITDB_ROOT_PASSWORD=mongo
RS=rs0
MONGODB_DATABASE=testing

# Key 
KEY_LEN=1024
KEY_FILE=secret.key

RED="\u001b[31m"
RESET="\u001b[0m"


# generate conf
compose(){
  # generate key file
  openssl rand -base64 756 > ${FOLDER}/${KEY_FILE}

  for NODE in ${NODE_LIST[@]}
  do
    HOST=${NODE%%:*}
    PORT=${NODE##*:}
    mkdir -p ${FOLDER}/${HOST}/node-${PORT}
    cp -r ${FOLDER}/${KEY_FILE} ${FOLDER}/${HOST}/node-${PORT}
    chmod 400 ${FOLDER}/${HOST}/node-${PORT}/${KEY_FILE}

    if [ ! -f "${FOLDER}/${HOST}/docker-compose.yaml" ]
    then
      cat << EOF | tee -a ${FOLDER}/${HOST}/docker-compose.yaml > /dev/null
services:
EOF
    fi
    
    cat << EOF | tee -a ${FOLDER}/${HOST}/docker-compose.yaml > /dev/null
  node-${PORT}:
    image: ${IMAGE}
    user: root
    ports:
      - ${PORT}:27017
    volumes:
      - ./node-${PORT}/${KEY_FILE}:/data/${KEY_FILE}
      - ./node-${PORT}/db:/data/db
      - ./node-${PORT}/backup:/data/backup
    environment: 
      TZ: Asia/Shanghai
      MONGODB_INITDB_ROOT_USERNAME: ${MONGODB_INITDB_ROOT_USERNAME}
      MONGODB_INITDB_ROOT_PASSWORD: ${MONGODB_INITDB_ROOT_PASSWORD}
    command:
      - "--wiredTigerCacheSizeGB"
      - "10.0"
      - "--replSet"
      - "${RS}"
      - "--keyFile"
      - /data/${KEY_FILE}
    restart: always
EOF
  done
}

show(){
  NODE_COUNT=${#NODE_LIST[*]}
  LAST_INDEX=$(expr ${NODE_COUNT} - 1)

  # print init rs
  printf "${RED}------------------------------------  init  ------------------------------------${RESET}\n\n"
  
  INDEX=0
  FIRST_NODE_PORT=${NODE_LIST[0]##*:}

  printf "docker compose exec node-%s bash\n\n" ${FIRST_NODE_PORT}
  printf "mongosh -u %s\n\n" ${MONGODB_INITDB_ROOT_USERNAME}
  printf "rs.initiate({\n"
  printf "   _id : \"%s\",\n" ${RS}
  printf "   members: [\n"

  for NODE in ${NODE_LIST[@]}
  do
    if [ ${INDEX} -lt  ${LAST_INDEX} ]
    then 
      printf "      { _id: %d, host: \"%s\" },\n" ${INDEX} ${NODE}
    else
      printf "      { _id: %d, host: \"%s\" }\n" ${INDEX} ${NODE}
    fi
    INDEX=$(expr ${INDEX} + 1)
  done
  printf "   ]\n"
  printf "});\n\n"
  
  # print connection url
  printf "${RED}---------------------------------  connection  ---------------------------------${RESET}\n\n"
  
  INDEX=0
  printf "mongosh \"mongodb://%s@" ${MONGODB_INITDB_ROOT_USERNAME}
  for NODE in ${NODE_LIST[@]}
  do
    if [ ${INDEX} -eq 0 ];then 
      printf "%s" ${NODE}
    else
      printf ",%s" ${NODE}
    fi
    INDEX=$(expr ${INDEX} + 1)
  done
  printf "/%s?" ${MONGODB_DATABASE}
  # Specify the database name associated with the user's credentials. 
  printf "authSource=admin"
  # replicaSet
  printf "&replicaSet=%s\"\n" ${RS}
  # connection about
  printf "&connectTimeoutMS=3000&maxPoolSize=100&minPoolSize=10\n"
  # Write Concern Options
  printf "&w=[ n | majority | tag set ]&journal=[ true | false ]&wtimeoutMS=[0]\n"
  # readConcern Options
  printf "&readConcernLevel=[ local | majority | linearizable | available ]\n"
  # readPreference
  printf "readPreference=[  primary | primaryPreferred | secondary | secondaryPreferred | nearest ]&maxStalenessSeconds=60\n"
  # other
  printf "&maxConnecting=5&maxIdleTimeMS=10000\n\n"

  printf "${RED}------------------------------------  dump  ------------------------------------${RESET}\n\n"

  INDEX=0
  FIRST_NODE_PORT=${NODE_LIST[0]##*:}
  printf "docker compose exec node-%d mongodump --uri=\"mongodb://%s@" ${FIRST_NODE_PORT} ${MONGODB_INITDB_ROOT_USERNAME}
  for NODE in ${NODE_LIST[@]};
  do
    if [ ${INDEX} -eq 0 ];then 
      printf "%s" ${NODE}
    else
      printf ",%s" ${NODE}
    fi
    INDEX=$(expr ${INDEX} + 1)  
  done
  printf "/%s?authSource=admin&replicaSet=%s\" --out=%s\n\n" ${MONGODB_DATABASE} ${RS} /data/backup

  printf "${RED}----------------------------------  restore  -----------------------------------${RESET}\n\n"
  
  INDEX=0
  FIRST_NODE_PORT=${NODE_LIST[0]##*:}
  printf "docker compose exec node-%d mongorestore --uri=\"mongodb://%s@" ${FIRST_NODE_PORT} ${MONGODB_INITDB_ROOT_USERNAME}
  for NODE in ${NODE_LIST[@]};do                                                                    \
    if [ ${INDEX} -eq 0 ];then 
      printf "%s" ${NODE}
    else
      printf ",%s" ${NODE}
    fi
    INDEX=$(expr ${INDEX} + 1)
  done
  printf "/?authSource=admin&replicaSet=%s\" --nsInclude=\"%s.*\" %s\n\n"  ${RS} ${MONGODB_DATABASE} /data/backup

  printf "${RED}--------------------------------------------------------------------------------${RESET}\n"
}


case "$1" in
  "show") show ;;
  "dc") compose ;;
  *) echo "USAGE : $0 [dc|show]"
    exit 1 ;;
esac
