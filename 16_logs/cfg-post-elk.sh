#!/bin/bash

#/etc/elasticsearch/jvm.options
#/etc/logstash/conf.d
#/etc/logstash/logstash.yml
#/etc/kibana/kibana.yml
#/etc/elasticsearch/elasticsearch.yml
#/etc/filebeat/filebeat.yml

chown -R logstash:logstash /etc/logstash/
#/usr/share/logstash/bin/system-install

#systemctl enable --now elasticsearch.service
#systemctl enable --now kibana.service
#systemctl enable --now logstash.service
systemctl enable elasticsearch.service
systemctl enable kibana.service
systemctl enable logstash.service
systemctl restart elasticsearch.service
systemctl restart kibana.service
systemctl restart logstash.service
