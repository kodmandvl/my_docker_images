#!/bin/sh
# Original: "You've hit <hostname>"(c) (luksa/kubia)
host_name_f="`hostname -f`"
host_name_i="`hostname -i`"
started="`TZ='Europe/Moscow' date +'%F %T %Z'`"
echo "You've hit $host_name_f (IP: $host_name_i, STARTED: $started)" > /ngnx/html/index.html && touch /var/log/nginx/index.html.done
