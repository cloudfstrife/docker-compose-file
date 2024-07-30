#!/bin/bash

FOLDER=`cd $(dirname $0);pwd`

# Node
INS_PER_NODE=5
NODE_LIST=( "192.168.43.222" )

# image 
IMAGE=mongodb/mongodb-community-server:7.0.12-ubuntu2204
# port
PORT_START=27017

# mongo environment
MONGODB_INITDB_ROOT_USERNAME=mongo
MONGODB_INITDB_ROOT_PASSWORD=mongo
RS=rs0

# Key 
KEY_LEN=1024
KEY_FILE=secret.key

RED="\u001b[31m"
RESET="\u001b[0m"


# generate conf
compose(){
  # generate key file
  openssl rand -base64 756 > ${FOLDER}/${KEY_FILE}

  for node in ${NODE_LIST[@]};do                                                    \
    mkdir -p ${FOLDER}/${node}
    cat << EOF | tee -a ${FOLDER}/${node}/docker-compose.yaml > /dev/null
services:
EOF

    for i in $(seq 1 ${INS_PER_NODE});do                                            \
      # create node-i folder
      mkdir -p ${FOLDER}/${node}/node-${i}
      # copy key file
      cp -r ${FOLDER}/${KEY_FILE} ${FOLDER}/${node}/node-${i}
      chmod 400 ${FOLDER}/${node}/node-${i}/${KEY_FILE} 
      # write node def
      cat << EOF | tee -a ${FOLDER}/${node}/docker-compose.yaml > /dev/null
  node-${i}:
    image: ${IMAGE}
    user: root
    ports:
      - `expr ${PORT_START} + ${i}`:27017
    volumes:
      - ./node-${i}/${KEY_FILE}:/data/${KEY_FILE}
      - ./node-${i}/db:/data/db
      - ./node-${i}/backup:/data/backup
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
  done
}

show(){
  NODE_COUNT=${#NODE_LIST[*]}
  INDEX=0
  LAST_INDEX=$(expr ${NODE_COUNT} \* ${INS_PER_NODE} - 1)

  # print init rs
  printf "${RED}-----------------------------------  init  -----------------------------------${RESET}\n\n"
  printf "docker compose exec node-1 bash\n\n"
  printf "mongosh -u %s -p %s \n\n" ${MONGODB_INITDB_ROOT_USERNAME} ${MONGODB_INITDB_ROOT_PASSWORD}
  printf "rs.initiate({\n"
  printf "   _id : \"%s\",\n" ${RS}
  printf "   members: [\n"

  for node in ${NODE_LIST[@]};do                                                                    \
    for i in $(seq 1 ${INS_PER_NODE});do                                                            \
      if [ ${INDEX} -lt  ${LAST_INDEX} ];then 
        printf "      { _id: %d, host: \"%s:%d\" },\n" ${INDEX} ${node} `expr ${PORT_START} + ${i}`
      else
        printf "      { _id: %d, host: \"%s:%d\" }\n" ${INDEX} ${node} `expr ${PORT_START} + ${i}`
      fi
      INDEX=$(expr ${INDEX} + 1)
    done
  done
  printf "   ]\n"
  printf "});\n\n"
  

  # print connection url
  INDEX=0
  printf "${RED}--------------------------------  connection  --------------------------------${RESET}\n\n"
  printf "mongodb://%s:%s@" ${MONGODB_INITDB_ROOT_USERNAME} ${MONGODB_INITDB_ROOT_PASSWORD}
  for node in ${NODE_LIST[@]};do                                                                    \
    for i in $(seq 1 ${INS_PER_NODE});do                                                            \
      if [ ${INDEX} -eq 0 ];then 
        printf "%s:%d" ${node} `expr ${PORT_START} + ${i} - 1`
      else
        printf ",%s:%d" ${node} `expr ${PORT_START} + ${i} - 1`
      fi
      INDEX=$(expr ${INDEX} + 1)
    done
  done
  printf "/DATABASE?"
  # Specify the database name associated with the user's credentials. 
  printf "authSource=admin"
  # replicaSet
  printf "&replicaSet=%s\n" ${RS}
  # connection about
  printf "&connectTimeoutMS=3000&maxPoolSize=100&minPoolSize=10\n"
  # Write Concern Options
  printf "&w=[ n | majority | tag set ]&journal=[ true | false ]&wtimeoutMS=[0]\n"
  # readConcern Options
  printf "&readConcernLevel=[ local | majority | linearizable | available ]\n"
  # readPreference
  printf "readPreference=[  primary | primaryPreferred | secondary | secondaryPreferred | nearest ]&maxStalenessSeconds=60\n"
  # other
  printf "&maxConnecting=5&maxIdleTimeMS=10000\n"
  printf "\n\n" 

  printf "${RED}-------------------------------------------------------------------------------${RESET}\n"
}

case "$1" in
  "show") show ;;
  "dc") compose ;;
  *) echo "USAGE : $0 [dc|show]"
    exit 1 ;;
esac
