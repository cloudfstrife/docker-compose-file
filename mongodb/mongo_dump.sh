#!/bin/bash

MONGODB_HOST=127.0.0.1
MONGODB_PORT=27017
MONGODB_USERNAME=mongo
MONGODB_PASSWORD=mongo
MONGODB_AUTH_SOURCE=admin
MONGODB_DATABASE=(testing)

OUTPUT_FOLDER_IN_CONTAINER=/data/backup

for DATABASE in ${MONGODB_DATABASE[@]} 
do 
    docker compose exec mongo mongodump \
    --host=${MONGODB_HOST} \
    --port=${MONGODB_PORT} \
    --username=${MONGODB_USERNAME} \
    --password=${MONGODB_PASSWORD} \
    --authenticationDatabase=${MONGODB_AUTH_SOURCE} \
    --db=${DATABASE} \
    --out=${OUTPUT_FOLDER_IN_CONTAINER}
done
