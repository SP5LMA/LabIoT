#!/usr/bin/env python3

from scapy.all import IP, ICMP, sr1
import sys
import time


def ping(dst, ttl=64):
    pkt = IP(dst=dst, ttl=ttl) / ICMP()
    ans = sr1(pkt, timeout=1, verbose=False)
    return ans


def main():
    if len(sys.argv) < 2:
        print(f"Użycie: {sys.argv[0]} <adres_docelowy>")
        sys.exit(1)

    dst = sys.argv[1]

    for i in range(4):
        ans = ping(dst)
        if ans:
            ip = ans[IP]
            print(f"{i}: odpowiedź z {ip.src}, ttl={ip.ttl}, len={len(ans)}")
        else:
            print(f"{i}: brak odpowiedzi")
        time.sleep(1)


if __name__ == "__main__":
    main()
