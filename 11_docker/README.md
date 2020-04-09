### Создать кастомный образ nginx на базе alpine

Готовим Dockerfile, сохраним в images/nginx.dkr
```
FROM alpine
RUN apk update && apk upgrade && apk add nginx
RUN mkdir -p /run/nginx # for pid file
RUN mkdir -p /var/www # for www root
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
COPY [ "nginx/conf/default.conf.no-php", "/etc/nginx/conf.d/default.conf" ]
COPY [ "nginx/www/index.html", "/var/www" ]
COPY [ "nginx/www/index.php", "/var/www" ]
EXPOSE 1234
ENTRYPOINT [ "nginx" ]
```
В файле ginx/conf/default.conf.no-php будет дефолтный конфиг для схемы без php

В файлах nginx/www/index.* будут дефолтные страницы
```
cat nginx/index.html
it works

cat nginx/www/index.php
<?php phpinfo(); ?>
```
Запускаем сборку, назовем образ mynginx
```
sudo docker build -t mynginx -f images/nginx.dkr .
```
Запускаем контейнер
```
sudo docker run -d -t 1234:80 mynginx
```
Проверка - http://localhost:1234 выдает "it works"

### Создать кастомные образы nginx и php, объединить их в docker-compose. После запуска nginx должен показывать php info

Готовим Dockerfile для php, сохраним в images/php.dkr
```
FROM alpine
RUN apk add php7-fpm
RUN sed -i 's/listen = 127\.0\.0\.1\:9000/listen = 9000/' etc/php7/php-fpm.d/www.conf
EXPOSE 9000
ENTRYPOINT ["/usr/sbin/php-fpm7", "-F"]
```
Запускаем сборку, назовем образ myphp
```
sudo docker build -t myphp -f images/php.dkr .
```
В файле nginx/conf/default.conf будет конфигурация nginx для php. Этот каталог будет монтироваться в контейнер mynginx.

Каталог nginx/www будет монтироваться в оба контейнера.

Соберем всё в docker compose и сохраним как docker-compose.yml
```
version: "3"
services:
  nginx:
    image: mynginx
    ports:
      - 1234:80
    volumes:
      - ./nginx/conf/:/etc/nginx/conf.d/
      - ./nginx/www:/var/www
    links:
      - myphp
  myphp:
    image: myphp
    volumes:
      - ./nginx/www:/var/www
```
Итоговая структура
```
.
├── docker-compose.yml
├── images
│   ├── nginx.dkr
│   └── php.dkr
└── nginx
    ├── conf
    │   ├── default.conf
    │   └── default.conf.no-php
    └── www
        ├── index.html
        └── index.php
```
Запускаем
```
sudo docker-compose up
```
Проверка - http://localhost:1234 выдает php info

### Загрузка в docker hub
```
docker login --username=yourhubusername --email=youremail@company.com
docker images
docker tag bb38976d03cf yourhubusername/verse_gapminder:firsttry
docker push yourhubusername/verse_gapminder
```
### Запуск docker compose с образами из docker hub

Поменяем в файле docker-compose.yml названия образов и сохраним как docker-compose-hub.yml
```
  nginx:
    image: pdpqbq/mynginx:otus
  myphp:
    image: pdpqbq/myphp:otus
```
Запускаем
```
sudo docker-compose -f docker-compose-hub.yml up
```
### Разница между контейнером и образом

Образ содержит файлы приложения и ОС. Контейнер это запущенный образ.

### Можно ли в контейнере собрать ядро?

Можно, если подготовить внутри контейнера всю инфраструктуру для сборки ядра.

### Полезные команды

clean up any resources — images, containers, volumes, and networks — that are dangling (not associated with a container)
```
docker system prune
```

additionally remove any stopped containers and all unused images (not just dangling images)
```
docker system prune -a
```
```
docker build -f Dockerfile .
docker ps
docker ps -a
docker run -d -p port:port container_name
docker stop container_name
docker logs container_name
docker inspect container_name
docker build -t dockerhub_login/reponame:ver
docker push/pull
docker exec -it container_name bash
```
