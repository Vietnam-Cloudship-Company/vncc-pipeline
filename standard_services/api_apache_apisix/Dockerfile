FROM apache/apisix:3.19.0-debian

USER root

COPY ./entrypoint.sh /usr/local/bin/apisix-entrypoint.sh
RUN chmod 0755 /usr/local/bin/apisix-entrypoint.sh

EXPOSE 9080

CMD ["/usr/local/bin/apisix-entrypoint.sh"]