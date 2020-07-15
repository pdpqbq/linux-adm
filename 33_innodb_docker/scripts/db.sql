CREATE DATABASE otus;
CREATE USER 'otus'@'%' IDENTIFIED BY 'otus';
GRANT ALL PRIVILEGES ON otus.* TO 'otus'@'%';
use otus;
create table tab1 (id int not null, name varchar(100), primary key (id));
insert into tab1 values (1,'petya');
insert into tab1 values (2,'vasya');
insert into tab1 values (3,'kolya');
