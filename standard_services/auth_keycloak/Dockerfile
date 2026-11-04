FROM quay.io/keycloak/keycloak:26.4.0 AS builder

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true

WORKDIR /opt/keycloak
COPY --chown=keycloak:keycloak keycloak.conf /opt/keycloak/conf/keycloak.conf
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.4.0

USER root
RUN microdnf install -y jq \
    && microdnf clean all

COPY --from=builder --chown=keycloak:keycloak /opt/keycloak/ /opt/keycloak/
COPY --chown=keycloak:keycloak realm-home.json /opt/keycloak/data/import-template/realm-home.json
COPY --chown=keycloak:keycloak entrypoint.sh /opt/keycloak/entrypoint.sh
COPY --chown=keycloak:keycloak themes/home/ /opt/keycloak/themes/home/
RUN sed -i 's/\r$//' /opt/keycloak/entrypoint.sh \
    && chmod 0755 /opt/keycloak/entrypoint.sh

USER keycloak
EXPOSE 8080 9000
ENTRYPOINT ["/opt/keycloak/entrypoint.sh"]
