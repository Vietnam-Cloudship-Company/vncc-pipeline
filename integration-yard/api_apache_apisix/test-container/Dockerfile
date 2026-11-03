FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y bash ca-certificates curl python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /yard
COPY main.sh /usr/local/bin/main.sh
COPY test-*.sh /yard/tests/
COPY mock-backend.py /yard/mock-backend.py
RUN chmod +x /usr/local/bin/main.sh /yard/tests/test-*.sh

ENTRYPOINT ["/usr/local/bin/main.sh"]
