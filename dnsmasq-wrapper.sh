#!/bin/sh

exec /usr/sbin/dnsmasq --port=0 --keep-in-foreground --enable-tftp --tftp-secure --user=nbxyz --tftp-root=/var/www/localhost/htdocs --log-facility=- --log-dhcp --log-queries "$@"