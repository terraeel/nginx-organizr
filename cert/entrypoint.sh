#!/bin/sh
if [ ! -e ${dhparam} ]; then cd /etc/ssl/certs/ && openssl dhparam -out dhparam.pem ${dhparam}; fi

if [ -z ${email+x} ]; then echo "Fatal: administrator email address must be specified with the environment variable named 'email'"; exit 1; fi
if [ -z ${domain+x} ]; then echo "Fatal: domains must be specified with the environment variable named 'domain'"; exit 1; fi

if [[ ! -f /etc/letsencrypt/live/{$domain}/fullchain.pem ]]; then
    echo "Could not find any previous certs. Aquiring new certificates."
    certbot certonly --standalone --noninteractive --agree-tos --email=${email} --domain=${domain}
else
    echo "Renewing"
    certbot certonly renew
fi

