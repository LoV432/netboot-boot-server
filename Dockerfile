FROM debian:bookworm AS builder
ARG RELEASE
ENV RELEASE=${RELEASE}

RUN apt update && apt install -y \
    ansible \
    curl \
    tar


WORKDIR /opt
RUN curl -sSL "https://github.com/netbootxyz/netboot.xyz/archive/refs/tags/${RELEASE}.tar.gz" -o release.tar.gz && \
    tar -xzf release.tar.gz && \
    mv "netboot.xyz-${RELEASE}" netboot.xyz

WORKDIR /opt/netboot.xyz

RUN ansible-playbook -i inventory site.yml


FROM alpine:latest

# /etc/netbootxyz/certs

RUN apk add --no-cache apache2
RUN rm -r /var/www/localhost
COPY --from=builder /var/www/html /var/www/localhost/htdocs
EXPOSE 80

CMD ["httpd", "-D" ,"FOREGROUND"]