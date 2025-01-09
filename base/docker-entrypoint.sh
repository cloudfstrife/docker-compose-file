#!/bin/sh

BEFORE_FOLDER=/init/before
AFTER_FOLDER=/init/after

if [ -d "${BEFORE_FOLDER}" ]
then
    for file in ${BEFORE_FOLDER}/*.sh
    do
        . ${file}
    done
fi

exec $@

if [ -d "${AFTER_FOLDER}" ]
then
    for file in ${AFTER_FOLDER}/*.sh
    do
        . ${file}
    done
fi