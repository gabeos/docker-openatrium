#!/bin/bash


# From phusion/passenger nginx-log-forwarder
set -e 

if [[ -e /var/log/apache2/error.log ]]; then
    exec tail -F /var/log/apache2/*.log
else 
    exec sleep 10
fi
