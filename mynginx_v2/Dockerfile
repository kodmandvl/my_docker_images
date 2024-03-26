# docker login
# docker build -t kodmandvl/mynginx:v2 .
# docker push kodmandvl/mynginx:v2
# docker run -d -p 8080:80 --name my8080 kodmandvl/mynginx:v2
# curl localhost:8080
# curl localhost:8080/cat.html
# curl localhost:8080/basic_status
# docker exec -it my8080 /bin/sh
FROM nginx:1.25.2-alpine-slim
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
COPY default.conf /etc/nginx/conf.d/
COPY *.html /usr/share/nginx/html/
