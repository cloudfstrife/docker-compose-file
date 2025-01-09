#!/bin/sh

if [ -d  /data/init/before ]
then
    for file in /data/init/before/*.sh
    do
        . ${file}
    done
fi

exec $@

if [ -d  /data/init/after ]
then
    for file in /data/init/after/*.sh
    do
        . ${file}
    done
fi