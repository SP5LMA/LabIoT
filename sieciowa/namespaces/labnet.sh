#!/bin/bash

set -e

### --- CLEANUP (IDEMPOTENT) -----------------------------------------------
# Usuwamy interfejsy veth jeśli istnieją
ip link del veth1 2>/dev/null || true
ip link del veth2 2>/dev/null || true
ip link del veth_ext 2>/dev/null || true

# Namespaces zostawiamy (nie przeszkadzają)
ip netns add h1 2>/dev/null || true
ip netns add h2 2>/dev/null || true
ip netns add r  2>/dev/null || true


### --- VETH: h1 <-> r -------------------------------------------------------
ip link add veth1 type veth peer name r1
ip link set veth1 netns h1
ip link set r1    netns r

### --- VETH: h2 <-> r -------------------------------------------------------
ip link add veth2 type veth peer name r2
ip link set veth2 netns h2
ip link set r2    netns r

### --- VETH: r <-> HOST (wyjście na świat) ----------------------------------
ip link add veth_ext type veth peer name r0
ip link set r0 netns r


### --- ADRESACJA ------------------------------------------------------------
# h1 <-> r
ip netns exec h1 ip addr add 10.0.1.2/24 dev veth1
ip netns exec r  ip addr add 10.0.1.1/24 dev r1

# h2 <-> r
ip netns exec h2 ip addr add 10.0.2.2/24 dev veth2
ip netns exec r  ip addr add 10.0.2.1/24 dev r2

# r <-> host
ip addr add        10.255.0.254/24 dev veth_ext
ip netns exec r ip addr add 10.255.0.1/24 dev r0


# UP interfejsów
ip netns exec h1 ip link set veth1 up
ip netns exec h1 ip link set lo up

ip netns exec h2 ip link set veth2 up
ip netns exec h2 ip link set lo up

ip netns exec r ip link set r1 up
ip netns exec r ip link set r2 up
ip netns exec r ip link set r0 up
ip netns exec r ip link set lo up

ip link set veth_ext up

### --- ROUTING --------------------------------------------------------------
# h1 i h2 → default via r
ip netns exec h1 ip route add default via 10.0.1.1
ip netns exec h2 ip route add default via 10.0.2.1

# r → default via host
ip netns exec r ip route add default via 10.255.0.254

ip netns exec r sysctl -w net.ipv4.ip_forward=1 >/dev/null

ip route replace 10.0.1.0/24 via 10.255.0.1 dev veth_ext
ip route replace 10.0.2.0/24 via 10.255.0.1 dev veth_ext

echo "Mini-sieć IoT gotowa!"
echo
echo "Przykłady testów:"
echo "  ip netns exec h1 ping -c3 10.0.1.1      # ping routera"
echo "  ip netns exec h1 ping -c3 10.255.0.254  # ping hosta"
echo "  ip netns exec h1 ping -c3 8.8.8.8       # ping Internetu (NAT)"
echo

