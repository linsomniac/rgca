#!/bin/bash -euxv

TMPDIR="$(mktemp -d)"
trap "rm -rf $TMPDIR" EXIT

cat <<@EOF >$TMPDIR/config.ini
[DEFAULT]
BITS=1024
CA_CERT_FILE=$TMPDIR/cacert.pem
CA_KEY_BITS=1024
CA_KEY_FILE=$TMPDIR/cacert.key
CA_PASSPHRASE=SuperSecure
CRL_FILE=$TMPDIR/crl.pem
CRL_VALID_DAYS=100
CERT_FILE=$TMPDIR/{{SUBJECT_CN}}.crt
INDEX_FILE=$TMPDIR/index.txt
KEY_FILE=$TMPDIR/{{SUBJECT_CN}}.key
SUBJECT_C=US
SUBJECT_EMAIL=user@example.com
SUBJECT_L=CityName
SUBJECT_O=Organization
SUBJECT_OU=OrgUnit
SUBJECT_ST=Colorado
VALID_DAYS=365

[dev]
CERT_TYPE=client server

[server]
BITS=2048
@EOF

export CONFIG=$TMPDIR/config.ini

#  From examples
./rgca ca new example.com
./rgca cert show $TMPDIR/cacert.pem
./rgca --config-group dev cert new dev1.example.com
./rgca --config-group dev cert new --san devtest.example.com dev2.example.com
./rgca --config-group dev cert new --append-domain .example.com --san foo --san bar dev3
./rgca --config-group server cert new --san example.com www.example.com
./rgca --config-group server --env-from-cert $TMPDIR/www.example.com.crt cert new --san IP:127.0.0.1
./rgca --config-group server --env-from-cert $TMPDIR/www.example.com.crt cert new --rm-san foo.example.com

figlet Success || echo === TEST SUCCESS ===
