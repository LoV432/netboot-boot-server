FROM debian:bookworm AS builder


RUN apt update && apt install -y \
    ansible \
    git


RUN git clone https://github.com/netbootxyz/netboot.xyz.git /opt/netboot.xyz

WORKDIR /opt/netboot.xyz

RUN ansible-playbook -i inventory site.yml


FROM alpine:latest

COPY --from=builder /var/www/html /var/www/html
# /etc/netbootxyz/certs

RUN apk add --no-cache apache2

EXPOSE 80

CMD ["httpd", "-D" ,"FOREGROUND"]