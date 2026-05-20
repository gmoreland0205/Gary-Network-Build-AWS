#!/bin/bash
dnf update -y
dnf install -y iptables-services

exec > /var/log/user-data.log 2>&1

echo "Starting NAT setup at $(date)"

# Enable IP forwarding
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Disable reverse path filtering (safe NAT config)
for iface in all default; do
  sysctl -w net.ipv4.conf.$iface.rp_filter=0
  echo "net.ipv4.conf.$iface.rp_filter=0" >> /etc/sysctl.conf
done

echo "Enabled IP forwarding and reverse path filtering at $(date)"

# Dynamically detect outbound interface
IFACE=$(ip route | awk '/default/ {print $5}')

echo "Detected outbound interface: $IFACE"

# Flush old NAT rules (optional but safer on re-runs)
iptables -t nat -F
iptables -F

echo "Flushed existing NAT rules at $(date)"

# NAT rule (dynamic interface)
iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

# Forwarding rules
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -s 10.0.0.0/16 -j ACCEPT

echo "NAT configured on interface: $IFACE at $(date)"

service iptables save || true