#!/bin/sh

exec /sbin/setuser nobody /usr/bin/memcached -m $MEMCACHED_MEM -p 11211 >>/var/log/memcached.log 2>&1
