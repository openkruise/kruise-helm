FROM alpine:latest

WORKDIR /app

RUN apk update

RUN apk add curl yaml yaml-dev g++ lua-dev lua luarocks

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

RUN alias luarocks=luarocks-5.1

RUN luarocks-5.1 install lyaml

COPY cmd-tool/ /app/