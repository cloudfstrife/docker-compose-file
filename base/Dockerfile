FROM debian:12.8

VOLUME [ "/data/init/before", "/data/init/after" ]

COPY docker-entrypoint.sh /usr/local/bin

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]

CMD [ "/bin/sh" ]
