FROM alpine:latest

WORKDIR /app

RUN apk update && \
    apk add curl yaml yaml-dev g++ lua-dev lua luarocks && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/ && \
    alias luarocks=luarocks-5.1 && \
    luarocks-5.1 install lyaml && \
    rm -rf /var/cache/apk/*

COPY cmd-tool/ /app/
