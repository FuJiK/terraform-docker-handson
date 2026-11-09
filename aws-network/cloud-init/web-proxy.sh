#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y squid

cat > /etc/squid/squid.conf <<'EOF'
acl db_subnet src 10.40.10.0/24
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 443
acl CONNECT method CONNECT
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow db_subnet
http_access deny all
http_port 3128
visible_hostname wordpress-lab-proxy
EOF

squid -k parse
systemctl enable --now squid
systemctl restart squid
