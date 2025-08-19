#!/bin/bash
openssl genrsa -out ca/tls.key 2048
openssl req -new -x509 -days 365 -key ca/tls.key -out ca/tls.crt -subj "/CN=TzafonCA"
openssl genrsa -out client/tls.key 2048
openssl req -new -key client/tls.key -out client/tls.csr -subj "/CN=TzafonClient"
openssl x509 -req -days 365 -in client/tls.csr -CA ca/tls.crt -CAkey ca/tls.key -CAcreateserial -out client/tls.crt
rm client/tls.csr
