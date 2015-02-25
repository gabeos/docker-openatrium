#!/bin/bash

sed -i \
    -e "s/\(root=\).*\$/\1$SSMTP_ROOT/g" \
    -e "s/\(mailhub=\).*\$/\1$SSMTP_MAILHUB/g" \
    -e "s/\(hostname=\).*\$/\1$SSMTP_HOSTNAME/g" \
    -e "s/\(UseSTARTTLS=\).*\$/\1$SSMTP_USE_STARTTLS/g" \
    -e "s/\(AuthUser=\).*\$/\1$SSMTP_AUTH_USER/g" \
    -e "s/\(AuthPass=\).*\$/\1$SSMTP_AUTH_PASS/g" \
    -e "s/\(AuthMethod=\).*\$/\1$SSMTP_AUTH_METHOD/g" \
    -e "s/\(FromLineOverride=\).*\$/\1$SSMTP_FROMLINE_OVERRIDE/g" \
    /etc/ssmtp/ssmtp.conf
