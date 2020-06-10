# Простая защита от ДДОС

https://gitlab.com/otus_linux/nginx-antiddos-example

## Защита от ДДОС средствами nginx
Написать конфигурацию nginx, которая даёт доступ клиенту только с определенной cookie.
Если у клиента её нет, нужно выполнить редирект на location, в котором кука будет добавлена, после чего клиент будет обратно отправлен (редирект) на запрашиваемый ресурс.

Смысл: умные боты попадаются редко, тупые боты по редиректам с куками два раза не пойдут

Для выполнения ДЗ понадобятся
* https://nginx.org/ru/docs/http/ngx_http_rewrite_module.html
* https://nginx.org/ru/docs/http/ngx_http_headers_module.html

* Самопроверка: docker run -p 80:80 your_account/your_repo:latest (или your_account/your_repo:advanced) - запустит nginx c выполненым заданием. сurl http://localhost/otus.txt - редирект(или ошибка) , открыв ту же страницу в браузере - увидим your_account/your_repo

Настройка nginx (сделано в образе):
```
server {
    location / {
        root /opt;
        if ($http_cookie !~* "otus=allow") {
            set $uuu $uri;
            rewrite ^/otus.txt$ /allow;
        }
        rewrite ^/otus.txt$ https://hub.docker.com/r/pdpqbq/nginxddos;
    location /allow {
        add_header Set-Cookie otus=allow;
        return 301 $uuu;
        }
    }
}
```
Или адрес открывается со второго раза:
```
server {
    location / {
        root /opt;
        if ($http_cookie !~* "otus") {
            add_header Set-Cookie otus=allow;
            return 200 error;
        }
        if ($http_cookie ~* "otus=allow") {
            rewrite ^/otus.txt$ http://google.ru;
        }
    }
```
Загрузка в docker hub:
```
sudo docker build -t nginxddos -f Dockerfile .
sudo docker images
sudo docker tag 237480d1ef91 pdpqbq/nginxddos:latest
sudo docker login docker.io
sudo docker push pdpqbq/nginxddos:latest
```
Проверка:
```
sudo docker run -p 80:80 pdpqbq/nginxddos:latest
```
