FROM apache/apisix:3.19.0-debian

USER root

# Copy custom APISIX configuration
COPY ./config.yaml /usr/local/apisix/conf/config.yaml

EXPOSE 9080 9443 9180 9091

CMD ["docker-start"]