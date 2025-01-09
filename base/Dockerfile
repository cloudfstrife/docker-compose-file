FROM debian:12.8

COPY docker-entrypoint.sh /entrypoint/

VOLUME [ "/init/before", "/init/after" ]

ENTRYPOINT [ "sh", "/entrypoint/docker-entrypoint.sh" ]

CMD [ "/bin/sh" ]
