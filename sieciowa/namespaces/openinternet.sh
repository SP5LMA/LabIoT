#!/bin/bash
set -e

# Włącz IP forwarding na hoście
sysctl -w net.ipv4.ip_forward=1 >/dev/null

# Trasy z hosta do sieci za r
ip route replace 10.0.1.0/24 via 10.255.0.1 dev veth_ext
ip route replace 10.0.2.0/24 via 10.255.0.1 dev veth_ext

# NAT na wyjściu do świata
iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Forward veth_ext <-> eth0
iptables -C FORWARD -i veth_ext -o eth0 -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -i veth_ext -o eth0 -j ACCEPT

iptables -C FORWARD -i eth0 -o veth_ext -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -i eth0 -o veth_ext -m state --state RELATED,ESTABLISHED -j ACCEPT

echo "NAT i routing na zewnątrz WŁĄCZONE (h1/h2 mają Internet)."
echo "Przykłady testów:"
echo -e "  \033[1mip netns exec h1 ping -c3 8.8.8.8\033[22m       # ping Internetu (NAT)"
echo

