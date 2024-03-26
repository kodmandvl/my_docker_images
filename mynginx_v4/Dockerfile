# docker login
# docker build -t kodmandvl/mynginx:v4 .
# docker push kodmandvl/mynginx:v4
# docker pull kodmandvl/mynginx:v4
# docker build -t kodmandvl/mynginx:latest .
# docker push kodmandvl/mynginx:latest
# docker pull kodmandvl/mynginx:latest
# docker images | grep mynginx
# docker run -d -p 8080:8080 --name myngnx -h myngnx kodmandvl/mynginx
# curl localhost:8080
# curl localhost:8080/kitty.html
# curl localhost:8080/basic_status
# docker exec -it myngnx /bin/sh
# docker logs myngnx
FROM nginx:1.25.2-alpine-slim
MAINTAINER Kodmandvl <kodmandvl@mail.ru>
WORKDIR /ngnx
RUN adduser -u 1080 -D ngnx && \
    mkdir -p /ngnx/html && \
    mkdir -p /ngnx/scripts && \
    chown -R ngnx:ngnx /ngnx && \
    chown -R ngnx:ngnx /var/log/nginx && \
    chown -R ngnx:ngnx /var/cache/nginx
COPY nginx.conf /etc/nginx/
COPY kitty.html /ngnx/html/
COPY index.sh /ngnx/scripts/
COPY entrypoint.sh /ngnx/scripts/
RUN chmod 775 /ngnx/scripts/*.sh && chown -R ngnx:ngnx /ngnx && chown -R ngnx:ngnx /usr/share/nginx/html
USER 1080
EXPOSE 8080
CMD ["/ngnx/scripts/entrypoint.sh"]
