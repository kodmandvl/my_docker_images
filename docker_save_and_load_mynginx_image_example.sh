##### SAVE AND LOAD IMAGES (WITH mynginx IMAGE AS EXAMPLE) #####

### SAVE IMAGES: ###
docker images | grep mynginx
docker pull kodmandvl/mynginx:v4
docker pull kodmandvl/mynginx:latest
docker pull kodmandvl/mynginx:v3
docker pull kodmandvl/mynginx:v2
docker pull kodmandvl/mynginx:v1
docker images | grep mynginx
mkdir -p ~/Distribs/docker_images_backup
docker save -o ~/Distribs/docker_images_backup/mynginx_v4.tar kodmandvl/mynginx:v4
docker save -o ~/Distribs/docker_images_backup/mynginx_v3.tar kodmandvl/mynginx:v3
docker save -o ~/Distribs/docker_images_backup/mynginx_v2.tar kodmandvl/mynginx:v2
docker save -o ~/Distribs/docker_images_backup/mynginx_v1.tar kodmandvl/mynginx:v1
ls -lFtrh ~/Distribs/docker_images_backup

### LOAD IMAGES: ###
docker rmi kodmandvl/mynginx:v4
docker rmi kodmandvl/mynginx:v3
docker rmi kodmandvl/mynginx:v2
docker rmi kodmandvl/mynginx:latest
docker rmi kodmandvl/mynginx:v1
docker images | grep mynginx
docker load -i ~/Distribs/docker_images_backup/mynginx_v4.tar 
docker load -i ~/Distribs/docker_images_backup/mynginx_v3.tar 
docker load -i ~/Distribs/docker_images_backup/mynginx_v2.tar 
docker load -i ~/Distribs/docker_images_backup/mynginx_v1.tar 
docker images | grep mynginx
# Видим, что метаданные совпадают с исходными.

### CHECK LOADED IMAGE: ###
docker run -d -p 8080:8080 --name myngnx -h myngnx kodmandvl/mynginx:v4
curl 127.0.0.1:8080
curl 127.0.0.1:8080/kitty.html
curl 127.0.0.1:8080/basic_status
docker rm -f myngnx 

### GZIP AND/OR ZIP TAR ARCHIVES: ###
cd ~/Distribs/docker_images_backup/
gzip -c mynginx_v4.tar > ./mynginx_v4.tar.gz
gzip -c mynginx_v3.tar > ./mynginx_v3.tar.gz
gzip -c mynginx_v2.tar > ./mynginx_v2.tar.gz
gzip -c mynginx_v1.tar > ./mynginx_v1.tar.gz
ls -alFtrh
zip mynginx_v4.tar.zip mynginx_v4.tar
zip mynginx_v3.tar.zip mynginx_v3.tar
zip mynginx_v2.tar.zip mynginx_v2.tar
zip mynginx_v1.tar.zip mynginx_v1.tar
ls -alFtrh

### DOCKER TAG EXAMPLE: ###
docker tag kodmandvl/mynginx:v4 mynginxsuper:latest
docker images | grep -e ^REPOSITORY -e mynginx
# Создается еще репозиторий, но IMAGE_ID тот же.

### DOCKER COMMIT EXAMPLE: ###
docker run -d -p 8080:8080 --name myngnx -h myngnx mynginxsuper
docker diff myngnx
docker exec -it myngnx /bin/sh
# We change /ngnx/html/index.html and /ngnx/html/kitty.html and then:
curl localhost:8080
curl localhost:8080/kitty.html
curl localhost:8080/basic_status
docker logs myngnx
docker diff myngnx
# Commit (as new image):
docker inspect myngnx
docker inspect myngnx | grep Id
docker inspect myngnx | grep Id | awk '{ print $2 }'
# Можно использовать или ID контейнера, или имя контейнера (ID см. выше или при запуске контейнера), ниже пример с именем:
docker commit -a "Dimka" -m "Changed" myngnx myngnx:changed
# (Однако такой способ создания не рекомендуется, рекомендуется через build)
# Проверим созданный образ:
docker rm -f myngnx
docker ps -a
docker images | grep myng
docker run -d -p 8080:8080 --name myngnx -h myngnx myngnx:changed
curl localhost:8080
curl localhost:8080/kitty.html
curl localhost:8080/basic_status
docker logs myngnx
docker diff myngnx
docker exec -it myngnx /bin/sh
# (удалим /ngnx/html/index.html и /var/log/nginx/index.html.done)
docker stop myngnx
docker start myngnx
docker diff myngnx
curl localhost:8080
# (как и ожидалось, при перезапуске контейнера был перегенерирован /ngnx/html/index.html и создан /var/log/nginx/index.html.done)

### SAVE (BACKUP) MORE IMAGES: ###
docker pull busybox:1.36
docker pull alpine:3.18
docker pull nginx:1.25.2-alpine-slim
docker pull debian:12.1
docker pull debian:11.7
docker pull rockylinux:8.8
docker pull postgres:16.0-alpine3.18
docker pull postgres:16.0-bookworm
cd ~/Distribs/docker_images_backup
docker save -o ~/Distribs/docker_images_backup/busybox_1.36.tar busybox:1.36
docker save -o ~/Distribs/docker_images_backup/alpine_3.18.tar alpine:3.18
docker save -o ~/Distribs/docker_images_backup/nginx_1.25.2-alpine-slim.tar nginx:1.25.2-alpine-slim
docker save -o ~/Distribs/docker_images_backup/debian_12.1.tar debian:12.1
docker save -o ~/Distribs/docker_images_backup/debian_11.7.tar debian:11.7
docker save -o ~/Distribs/docker_images_backup/rockylinux_8.8.tar rockylinux:8.8
docker save -o ~/Distribs/docker_images_backup/postgres_16.0-alpine3.18.tar postgres:16.0-alpine3.18
docker save -o ~/Distribs/docker_images_backup/postgres_16.0-bookworm.tar postgres:16.0-bookworm
ls -lFtrh ~/Distribs/docker_images_backup
gzip -c busybox_1.36.tar > ./busybox_1.36.tar.gz
gzip -c alpine_3.18.tar > ./alpine_3.18.tar.gz
gzip -c nginx_1.25.2-alpine-slim.tar > ./nginx_1.25.2-alpine-slim.tar.gz
gzip -c debian_12.1.tar > ./debian_12.1.tar.gz
gzip -c debian_11.7.tar > ./debian_11.7.tar.gz
gzip -c rockylinux_8.8.tar > ./rockylinux_8.8.tar.gz
gzip -c postgres_16.0-alpine3.18.tar > ./postgres_16.0-alpine3.18.tar.gz
gzip -c postgres_16.0-bookworm.tar > ./postgres_16.0-bookworm.tar.gz

### SAVE (BACKUP) MY ROCKY LINUX 88 IMAGES: ###
cd ~/Distribs/docker_images_backup
docker save -o ~/Distribs/docker_images_backup/myrocky88_s.tar kodmandvl/myrocky88:s
docker save -o ~/Distribs/docker_images_backup/myrocky88_m.tar kodmandvl/myrocky88:m
docker save -o ~/Distribs/docker_images_backup/myrocky88_l.tar kodmandvl/myrocky88:l
docker save -o ~/Distribs/docker_images_backup/myrocky88_xl.tar kodmandvl/myrocky88:xl
docker save -o ~/Distribs/docker_images_backup/myrocky88_xxl.tar kodmandvl/myrocky88:xxl
docker save -o ~/Distribs/docker_images_backup/myrocky88_xxxl.tar kodmandvl/myrocky88:xxxl
ls -lFtrh ~/Distribs/docker_images_backup/
gzip -c myrocky88_s.tar > ./myrocky88_s.tar.gz
gzip -c myrocky88_m.tar > ./myrocky88_m.tar.gz
gzip -c myrocky88_l.tar > ./myrocky88_l.tar.gz
gzip -c myrocky88_xl.tar > ./myrocky88_xl.tar.gz
gzip -c myrocky88_xxl.tar > ./myrocky88_xxl.tar.gz
gzip -c myrocky88_xxxl.tar > ./myrocky88_xxxl.tar.gz
ls -lFtrh ~/Distribs/docker_images_backup/
rm -v myrocky88_s.tar
rm -v myrocky88_m.tar
rm -v myrocky88_l.tar
rm -v myrocky88_xl.tar
rm -v myrocky88_xxl.tar
rm -v myrocky88_xxxl.tar
sha256sum myrocky88_s.tar.gz > ./myrocky88_s.tar.gz.sha256sum
sha256sum myrocky88_m.tar.gz > ./myrocky88_m.tar.gz.sha256sum
sha256sum myrocky88_l.tar.gz > ./myrocky88_l.tar.gz.sha256sum
sha256sum myrocky88_xl.tar.gz > ./myrocky88_xl.tar.gz.sha256sum
sha256sum myrocky88_xxl.tar.gz > ./myrocky88_xxl.tar.gz.sha256sum
sha256sum myrocky88_xxxl.tar.gz > ./myrocky88_xxxl.tar.gz.sha256sum
ls -lFtrh ~/Distribs/docker_images_backup/

### SAVE (BACKUP) MY POSTGRES 16 IMAGE ON ROCKY LINUX 8.8: ###
cd ~/Distribs/docker_images_backup
docker save -o ~/Distribs/docker_images_backup/mypostgres16_rocky88.tar kodmandvl/mypostgres16:rocky88
docker save -o ~/Distribs/docker_images_backup/mypostgres16_slim_rocky88.tar kodmandvl/mypostgres16:slim-rocky88
ls -lFtrh ~/Distribs/docker_images_backup/
gzip -c mypostgres16_rocky88.tar > ./mypostgres16_rocky88.tar.gz
gzip -c mypostgres16_slim_rocky88.tar > ./mypostgres16_slim_rocky88.tar.gz
ls -lFtrh ~/Distribs/docker_images_backup/
rm -v mypostgres16_rocky88.tar
rm -v mypostgres16_slim_rocky88.tar
sha256sum mypostgres16_rocky88.tar.gz > ./mypostgres16_rocky88.tar.gz.sha256sum
sha256sum mypostgres16_slim_rocky88.tar.gz > ./mypostgres16_slim_rocky88.tar.gz.sha256sum
ls -lFtrh ~/Distribs/docker_images_backup/

