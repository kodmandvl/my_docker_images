# docker login
# docker build -t kodmandvl/mynginx:v3 .
# docker push kodmandvl/mynginx:v3
# docker pull kodmandvl/mynginx:v3
# docker build -t kodmandvl/mynginx:latest .
# docker push kodmandvl/mynginx:latest
# docker pull kodmandvl/mynginx:latest
# docker images | grep mynginx
# docker run -d -p 8080:80 --name my8080 -h my8080 kodmandvl/mynginx
# curl localhost:8080
# curl localhost:8080/kitty.html
# curl localhost:8080/basic_status
# docker exec -it my8080 /bin/sh
FROM nginx:1.25.2-alpine-slim
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
COPY default.conf /etc/nginx/conf.d/
COPY index.sh /usr/share/nginx/html/
COPY kitty.html /usr/share/nginx/html/
COPY docker-entrypoint.sh /
RUN chmod 775 /docker-entrypoint.sh && chmod 775 /usr/share/nginx/html/index.sh
