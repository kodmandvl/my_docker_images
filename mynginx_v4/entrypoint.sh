#!/bin/sh

if [ ! -f /var/log/nginx/index.html.done ]; then
    /ngnx/scripts/index.sh
fi

nginx -g 'daemon off;'
