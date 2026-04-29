#!/bin/bash
set -eux

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1

# Persist across reboot
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

# NAT configuration
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Save rules (Amazon Linux 2 / RHEL-like systems)
yum install -y iptables-services || true
service iptables save || true