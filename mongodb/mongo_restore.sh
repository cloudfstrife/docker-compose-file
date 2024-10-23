#!/bin/bash

FOLDER=`cd $(dirname $0);pwd`

MONGODB_HOST=127.0.0.1
MONGODB_PORT=27017
MONGODB_USERNAME=mongo
MONGODB_PASSWORD=mongo
MONGODB_AUTH_SOURCE=admin
MONGODB_DATABASE=(testing)

RED="\u001b[31m"
RESET="\u001b[0m"

# folder path where storage the dump file 
DUMP_FOLDER=${FOLDER}/backup

# folder path in container where storage the dump file
DUMP_FOLDER_IN_CONTAINER=/data/backup

for DATABASE in ${MONGODB_DATABASE[@]} 
do 
    if [ -d ${DUMP_FOLDER}/${DATABASE} ]
    then
        docker compose exec mongo mongorestore \
            --host=${MONGODB_HOST} \
            --port=${MONGODB_PORT} \
            --username=${MONGODB_USERNAME} \
            --password=${MONGODB_PASSWORD} \
            --authenticationDatabase=${MONGODB_AUTH_SOURCE} \
            --db=${DATABASE} \
            ${DUMP_FOLDER_IN_CONTAINER}/${DATABASE}
    else
        printf "${RED} [ ERROR ] folder %s not found${RESET}\n"  ${DUMP_FOLDER_IN_CONTAINER}/${DATABASE}
    fi
done
