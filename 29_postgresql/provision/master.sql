alter system set listen_addresses to '*';
select pg_create_physical_replication_slot('slot1');
alter user postgres with password 'postgres';
create user replicator with replication password 'postgres';
create database otus;
\c otus
create table t(id int, pad char(200));
insert into t select generate_series(1,1000000) as id, md5(random()::text) as pad;

create user barman with superuser nocreatedb login password 'barman';
create user streaming_barman with login replication password 'barman';

select pg_reload_conf();
