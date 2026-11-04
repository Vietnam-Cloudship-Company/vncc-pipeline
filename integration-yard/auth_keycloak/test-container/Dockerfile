FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y bash ca-certificates curl jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /yard
COPY main.sh /usr/local/bin/main.sh
COPY test-*.sh /yard/tests/
RUN sed -i 's/\r$//' /usr/local/bin/main.sh /yard/tests/test-*.sh \
    && chmod +x /usr/local/bin/main.sh /yard/tests/test-*.sh

ENTRYPOINT ["/usr/local/bin/main.sh"]