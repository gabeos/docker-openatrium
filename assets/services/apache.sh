#!/bin/sh

exec apache2 -DFOREGROUND >>/var/log/apache.log 2>&1
