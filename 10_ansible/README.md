### Первые шаги с Ansible

Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:
- необходимо использовать модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными
- после установки nginx должен быть в режиме enabled в systemd
- должен быть использован notify для старта nginx после установки
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible
* Сделать все это с использованием Ansible роли

Подготовим структуру каталогов
```
ansible-galaxy init roles/nginx
```
В файле ansible.cfg укажем путь к inventory = staging/hosts.yml

Скриптом config.sh возьмем настройки vagrant ssh для нашей ВМ (после vagrant up) и запишем их в inventory

Плейбук playbooks/nginx.yml использует шаблон templates/nginx.conf.j2

Файлы для роли находятся в roles/nginx
```
.
├── ansible.cfg
├── config.sh
├── playbooks
│   ├── nginx.yml
│   ├── role-nginx.yml
│   └── templates
│       └── nginx.conf.j2
├── README.md
├── roles
│   └── nginx
│       ├── files
│       ├── handlers
│       │   └── main.yml
│       ├── README.md
│       ├── tasks
│       │   └── main.yml
│       ├── templates
│       │   └── nginx.conf.j2
│       └── vars
│           └── main.yml
├── staging
│   └── hosts.yml
└── Vagrantfile
```
Проверка
```
ansible-inventory --list
ansible nginx -m ping
```
Запуск
```
ansible-playbook playbooks/nginx.yml
ansible-playbook playbooks/role-nginx.yml
```
Или для автоматической установки nginx добавим в Vagrantfile
```
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbooks/role-nginx.yml"
end
```
