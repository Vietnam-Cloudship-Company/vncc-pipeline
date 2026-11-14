FROM quay.io/keycloak/keycloak:26.4.0

ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true

COPY --chown=keycloak:keycloak entrypoint.sh /opt/keycloak/entrypoint.sh
RUN sed -i 's/\r$//' /opt/keycloak/entrypoint.sh \
    && chmod 0755 /opt/keycloak/entrypoint.sh

USER keycloak
EXPOSE 8080 9000
ENTRYPOINT ["/opt/keycloak/entrypoint.sh"]
