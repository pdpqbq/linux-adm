#!/bin/bash

#HOST=$1
#shift
HOST="192.168.255.1"
for ARG in "$@"; do nc -4vzu $HOST $ARG; done
ssh $HOST
