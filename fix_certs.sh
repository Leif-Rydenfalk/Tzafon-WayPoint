#!/bin/bash

# Clean up existing certificates
sudo rm -rf /etc/ssl_certs
sudo mkdir -p /etc/ssl_certs/{ca,server,client}

# Generate CA private key
sudo openssl genrsa -out /etc/ssl_certs/ca/tls.key 2048

# Generate CA certificate
sudo openssl req -new -x509 -key /etc/ssl_certs/ca/tls.key -sha256 \
    -subj "/C=US/ST=CA/O=Dev/CN=DevCA" \
    -days 3650 \
    -out /etc/ssl_certs/ca/tls.crt

# Generate server private key
sudo openssl genrsa -out /etc/ssl_certs/server/tls.key 2048

# Create server config file with proper v3 extensions
sudo tee /etc/ssl_certs/server.conf > /dev/null <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
O = Dev
CN = localhost

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generate server certificate signing request
sudo openssl req -new -key /etc/ssl_certs/server/tls.key \
    -out /etc/ssl_certs/server/tls.csr \
    -config /etc/ssl_certs/server.conf

# Sign server certificate with CA
sudo openssl x509 -req -in /etc/ssl_certs/server/tls.csr \
    -CA /etc/ssl_certs/ca/tls.crt \
    -CAkey /etc/ssl_certs/ca/tls.key \
    -CAcreateserial \
    -out /etc/ssl_certs/server/tls.crt \
    -days 365 \
    -extensions v3_req \
    -extfile /etc/ssl_certs/server.conf

# Generate client private key
sudo openssl genrsa -out /etc/ssl_certs/client/tls.key 2048

# Create client config file
sudo tee /etc/ssl_certs/client.conf > /dev/null <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = CA
O = Dev
CN = client

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

# Generate client certificate signing request
sudo openssl req -new -key /etc/ssl_certs/client/tls.key \
    -out /etc/ssl_certs/client/tls.csr \
    -config /etc/ssl_certs/client.conf

# Sign client certificate with CA
sudo openssl x509 -req -in /etc/ssl_certs/client/tls.csr \
    -CA /etc/ssl_certs/ca/tls.crt \
    -CAkey /etc/ssl_certs/ca/tls.key \
    -CAcreateserial \
    -out /etc/ssl_certs/client/tls.crt \
    -days 365 \
    -extensions v3_req \
    -extfile /etc/ssl_certs/client.conf

# Clean up CSR and config files
sudo rm /etc/ssl_certs/server/tls.csr /etc/ssl_certs/client/tls.csr
sudo rm /etc/ssl_certs/server.conf /etc/ssl_certs/client.conf

# Set proper permissions
sudo chmod 600 /etc/ssl_certs/*/tls.key
sudo chmod 644 /etc/ssl_certs/*/tls.crt

echo "Certificates generated successfully!"
echo "CA cert: /etc/ssl_certs/ca/tls.crt"
echo "Server cert: /etc/ssl_certs/server/tls.crt"
echo "Client cert: /etc/ssl_certs/client/tls.crt"

# Verify certificates
echo "Verifying certificates..."
sudo openssl x509 -in /etc/ssl_certs/ca/tls.crt -text -noout | grep -A2 "Version"
sudo openssl x509 -in /etc/ssl_certs/server/tls.crt -text -noout | grep -A2 "Version"
sudo openssl x509 -in /etc/ssl_certs/client/tls.crt -text -noout | grep -A2 "Version"