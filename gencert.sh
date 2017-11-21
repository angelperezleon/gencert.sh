#!/bin/bash

# Bash shell script for generating self-signed certs. Run this in a folder, as it
# generates a few files. Large portions of this script were taken from the
# following artcile:
# 
# http://usrportage.de/archives/919-Batch-generating-SSL-certificates.html
# 
# Additional alterations by: Brad Landers
# Date: 2012-01-27
# Further alterations by: https://github.com/angelperezleon
# Date: 21.11.2017

# Set permissions: chmod +x gencert.sh
# Usage: gencert.sh <domain>

# Generate date - still to integrate!
# like to add timestamp to generated cert files
TIMESTAMP="$(date  +%d-%m-%Y-%H:%M:%S)"

# Script accepts a single argument, the fqdn for the cert
DOMAIN="$1"
if [ -z "$DOMAIN" ]; then
  echo "Usage: $(basename $0) <domain>"
  exit 11
fi

fail_if_error() {
  [ $1 != 0 ] && {
    unset PASSPHRASE
    exit 10
  }
}

# Generate a passphrase
export PASSPHRASE=$(head -c 500 /dev/urandom | tr -dc a-z0-9A-Z | head -c 128; echo)

# Certificate details; replace items in angle brackets with your own info
# Example: ST=<CITY> - ST=New York
subj="
C=<US>
ST=<CITY>
O=<CITY>
localityName=<CITY>
commonName=$DOMAIN
organizationalUnitName=<DEPARTMENT>
emailAddress=<YOUR@EMAIL.com>
"

# Generate the server private key
openssl genrsa -des3 -out $DOMAIN.key -passout env:PASSPHRASE 2048
fail_if_error $?

# Generate the CSR
openssl req \
    -new \
    -batch \
    -subj "$(echo -n "$subj" | tr "\n" "/")" \
    -key $DOMAIN.key \
    -out $DOMAIN.csr \
    -passin env:PASSPHRASE
fail_if_error $?
cp $DOMAIN.key $DOMAIN.key.org
fail_if_error $?

# Strip the password so we don't have to type it every time we restart Apache
openssl rsa -in $DOMAIN.key.org -out $DOMAIN.key -passin env:PASSPHRASE
fail_if_error $?

# Generate the cert (good for 10 years)
# openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt
openssl x509 -req -days 3650 -in $DOMAIN.csr -signkey $DOMAIN.key -out $DOMAIN.crt

# Generate p12 cert file to use for importing into IE/Mozilla
# openssl pkcs12 -inkey key.pem -in cert.pem -export -out certificate.p12
openssl pkcs12 -inkey $DOMAIN.key -in $DOMAIN.crt -export -out $DOMAIN.p12

openssl pkcs12 -in $DOMAIN.p12 -noout -info

fail_if_error $?
