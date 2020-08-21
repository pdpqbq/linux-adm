#!/bin/bash

# from https://raymii.org/s/tutorials/Keepalived_notify_script_execute_action_on_failover.html

TYPE=$1
NAME=$2
STATE=$3
case $STATE in
        "MASTER") /usr/bin/systemctl start mattermost
                  ;;
        "BACKUP") /usr/bin/systemctl stop mattermost
                  ;;
        "FAULT")  /usr/bin/systemctl stop mattermost
                  exit 0
                  ;;
        *)        /sbin/logger "mattermost unknown state"
                  exit 1
                  ;;
esac
