#!/bin/sh
host_name_f="`hostname -f`"
host_name_i="`hostname -i`"
created="`TZ='Europe/Moscow' date +'%F %T %Z'`"
echo "<!DOCTYPE html>
<html>
<head>
<title>$host_name_f - My Nginx v4 (based on nginx:1.25.2-alpine-slim)</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Hello from Dimka!</h1>
<p>If you see this page, My Nginx v4 on $host_name_f (based on nginx:1.25.2-alpine-slim) is successfully installed and
working.</p>
<p> HOST: $host_name_f </p>
<p> IP: $host_name_i </p>
<p> CREATED: $created </p>
</body>
</html>" > /ngnx/html/index.html && touch /var/log/nginx/index.html.done
