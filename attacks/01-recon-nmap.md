# Attack 1 — Reconnaissance (Nmap port scanning)

> ⚠️ Run only inside your own lab, from the Kali VM (VLAN 10) against your own
> target server (VLAN 20). This is the first thing a real attacker does: map the
> network before striking.

## What the attacker does

From **Kali (10.10.10.100)**:

```bash
# Host discovery — who is alive?
nmap -sn 10.10.20.0/24

# Vertical scan — which TCP ports are open on the target server?
nmap -sS -p- 10.10.20.100

# Service/version detection
nmap -sV -sC 10.10.20.100

# Horizontal scan — same port across many hosts
nmap -sS -p 22 10.10.20.0/24
```

## What should happen (defence)

1. The **`-sS` SYN scan** sends a flood of TCP packets with only the **SYN flag**
   set, to many ports, fast. It never completes the 3-way handshake.
2. Suricata rule **SID 1000001** (`SECUREHOME Nmap-style TCP SYN scan`) fires once
   the threshold (30 SYNs in 5s from one source) is crossed.
3. The alert appears in Grafana within ~10s: a spike on *Alerts over time* and a
   new row in the *Alert signatures* table.
4. NULL/XMAS scans (`nmap -sN`, `nmap -sX`) trigger SID 1000002 / 1000003.

## Verify on the Pi

```bash
tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert") | {sig:.alert.signature, src:.src_ip, dst:.dest_ip}'
```

## How to explain it in the interview (OSI / TCP)

- **Layer 3 (IP):** attacker is probing many destination addresses/ports.
- **Layer 4 (TCP):** a normal connection = SYN → SYN/ACK → ACK (3-way handshake).
  A SYN scan sends **only SYN** and walks away — that half-open pattern, repeated,
  is the signature we detect.
- **Detection logic:** we don't block one SYN (normal). We count SYNs per source
  over time (`threshold`) — *behaviour*, not a single packet. That's the core idea
  of anomaly-style IDS detection.
