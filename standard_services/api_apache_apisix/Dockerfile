FROM apache/apisix:3.19.0-debian

USER root

# APISIX standalone declarative configuration and its environment-rendered routes.
COPY ./config.yaml /usr/local/apisix/conf/config.yaml
COPY ./apisix.yaml.template /usr/local/apisix/conf/apisix.yaml.template
COPY ./entrypoint.sh /usr/local/bin/apisix-entrypoint.sh
RUN chmod 0755 /usr/local/bin/apisix-entrypoint.sh

EXPOSE 9080

CMD ["/usr/local/bin/apisix-entrypoint.sh"]