FROM debian:bookworm AS builder
ARG RELEASE
ENV RELEASE=${RELEASE}

ARG BOOT_DOMAIN=netboot-boot.monib.xyz
ENV BOOT_DOMAIN=${BOOT_DOMAIN}

ARG LIVE_ENDPOINT=https://netboot-assets.monib.xyz/
ENV LIVE_ENDPOINT=${LIVE_ENDPOINT}

RUN apt update && apt install -y \
    ansible \
    curl \
    tar


WORKDIR /opt
RUN curl -sSL "https://github.com/netbootxyz/netboot.xyz/archive/refs/tags/${RELEASE}.tar.gz" -o release.tar.gz && \
    tar -xzf release.tar.gz && \
    mv "netboot.xyz-${RELEASE}" netboot.xyz

WORKDIR /opt/netboot.xyz
RUN echo "boot_domain: ${BOOT_DOMAIN}" >> user_overrides.yml
RUN echo "live_endpoint: ${LIVE_ENDPOINT}" >> user_overrides.yml

RUN ansible-playbook -i inventory site.yml


FROM alpine:latest

# /etc/netbootxyz/certs

RUN apk add --no-cache apache2 supervisor dnsmasq bash
RUN rm -r /var/www/localhost
COPY --from=builder /var/www/html /var/www/localhost/htdocs

COPY <<EOF /usr/local/bin/dnsmasq-wrapper.sh
#!/bin/bash

echo "[dnsmasq] Starting TFTP server on port 69"
echo "[dnsmasq] TFTP root: /var/www/localhost/htdocs"
echo "[dnsmasq] TFTP security: enabled"
echo "[dnsmasq] Logging: enabled (dhcp and queries)"

exec /usr/sbin/dnsmasq --port=0 --keep-in-foreground --enable-tftp --tftp-secure --tftp-root=/var/www/localhost/htdocs --log-facility=- --log-dhcp --log-queries "$@"
EOF

RUN chmod +x /usr/local/bin/dnsmasq-wrapper.sh

COPY <<EOF /etc/supervisord.conf
[supervisord]
nodaemon=true

[program:httpd]
command=/usr/sbin/httpd -D FOREGROUND
autorestart=true

[program:tftpd]
command=/usr/local/bin/dnsmasq-wrapper.sh
redirect_stderr=true
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
EOF

EXPOSE 80 69/udp

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]