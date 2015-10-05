#!/bin/bash
if [ ! -f /etc/httpd/ssl/server.key ]; then
        mkdir -p /etc/httpd/ssl
        KEY=/etc/httpd/ssl/server.key
        DOMAIN=$(hostname)
        export PASSPHRASE=$(cat /dev/urandom | tr -cd 'a-f0-9' | head -c 16)
        SUBJ="
C=US
ST=Texas
O=University of Texas
localityName=Austin
commonName=$DOMAIN
organizationalUnitName=TACC
emailAddress=admin@$DOMAIN
"
        openssl genrsa -des3 -out /etc/httpd/ssl/server.key -passout env:PASSPHRASE 2048
        openssl req -new -batch -subj "$(echo -n "$SUBJ" | tr "\n" "/")" -key $KEY -out /tmp/$DOMAIN.csr -passin env:PASSPHRASE
        cp $KEY $KEY.orig
        openssl rsa -in $KEY.orig -out $KEY -passin env:PASSPHRASE
        openssl x509 -req -days 365 -in /tmp/$DOMAIN.csr -signkey $KEY -out /etc/httpd/ssl/server.crt
fi

HOSTLINE=$(echo $(ip -f inet addr show eth0 | grep 'inet' | awk '{ print $2 }' | cut -d/ -f1) $(hostname) $(hostname -s))
echo $HOSTLINE >> /etc/hosts

# link in the ssl certs at runtime to allow for valid certs to be mounted in a volume
ln -s /etc/httpd/ssl/server.key /etc/pki/tls/private/server.key
ln -s /etc/httpd/ssl/server.crt /etc/pki/tls/certs/server.crt

# if a ca bundle is present, load it and update the ssl.conf file
if [[ -e /etc/httpd/ssl/ca-bundle.crt ]]; then
  ln -s /etc/httpd/ssl/ca-bundle.crt /etc/pki/tls/certs/server-ca-chain.crt
  set -i 's/#SSLCACertificateFile/SSLCACertificateFile/' /etc/httpd/conf.d/ssl.conf
fi

# if a ca cert chain file is present, load it and update the ssl.conf file
if [[ -e /etc/httpd/ssl/ca-chain.crt ]]; then
  ln -s /etc/httpd/ssl/ca-chain.crt /etc/pki/tls/certs/server-ca-chain.crt
  set -i 's/#SSLCertificateChainFile/SSLCertificateChainFile/' /etc/httpd/conf.d/ssl.conf
fi

#Setup URL for Controller
if [[ ! -z $BASE_URL ]]; then
  mysql -h db -u${DB_ENV_MYSQL_USER} -p${DB_ENV_MYSQL_PASSWORD} --database=${DB_ENV_MYSQL_DATABASE} \
  -e "UPDATE settings SET value = '${BASE_URL}' WHERE setting = 'baseurl';"
fi

# finally, start docker
/usr/sbin/httpd -DFOREGROUND
