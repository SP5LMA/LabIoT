#!/bin/bash
set -e

# Wyłącz IP forwarding na hoście
sysctl -w net.ipv4.ip_forward=0 >/dev/null || true

# Usuń reguły (najprościej: selektywnie albo flush)
iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
iptables -D FORWARD -i veth_ext -o eth0 -j ACCEPT 2>/dev/null || true
iptables -D FORWARD -i eth0 -o veth_ext -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || true

echo "NAT i forwarding na zewnątrz WYŁĄCZONE (piaskownica offline)."

