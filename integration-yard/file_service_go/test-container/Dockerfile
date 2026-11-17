FROM python:3.12-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /yard
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.sh /usr/local/bin/main.sh
COPY tests/ /yard/tests/
RUN chmod +x /usr/local/bin/main.sh

ENTRYPOINT ["/usr/local/bin/main.sh"]
