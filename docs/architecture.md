# Architecture & Design

## Design goal

Build a small network that behaves like a real company network: multiple
**segments** (zones) with different trust levels, a **firewall/IDS** watching the
boundary, and the ability to **prove** that segmentation and detection work.

The single most important security idea demonstrated here is **segmentation**:
an untrusted device (IoT) must not be able to reach sensitive systems (Servers),
even though they are on the same physical kit. We enforce that with VLANs + ACLs,
then we *attack across the boundary* to prove the control holds.

## Zones (VLANs)

| VLAN | Name    | Subnet          | Gateway (SVI)   | Trust    | What lives here |
|------|---------|-----------------|-----------------|----------|-----------------|
| 10   | USERS   | 10.10.10.0/24   | 10.10.10.1      | Medium   | Kali (attacker / pentester workstation) |
| 20   | SERVERS | 10.10.20.0/24   | 10.10.20.1      | High     | Target server VM (SSH, web, DNS) |
| 30   | IoT     | 10.10.30.0/24   | 10.10.30.1      | **Low**  | Untrusted IoT device |
| 99   | MGMT    | 10.10.99.0/24   | 10.10.99.1      | Admin    | Device management only |

### Segmentation policy (enforced by ACL on SW1)

| From ↓ / To → | USERS | SERVERS | IoT | Internet |
|---------------|:-----:|:-------:|:---:|:--------:|
| **USERS**     | —     | ✅ (web/ssh only) | ❌ | ✅ |
| **SERVERS**   | ✅ (replies) | — | ❌ | ✅ (updates) |
| **IoT**       | ❌    | ❌      | —   | ✅ (DNS/HTTPS only) |

Rule of thumb enforced: **IoT can reach the internet but nothing internal.**
That single rule is what the demo proves with an attack.

## Addressing

| Link                | Network         | Notes |
|---------------------|-----------------|-------|
| R1 ↔ Internet (NAT) | DHCP / 203.0.113.0/24 | PAT overload to WAN |
| R1 ↔ SW1 trunk      | 802.1Q          | carries VLANs 10/20/30/99 |
| Loopback R1         | 1.1.1.1/32      | OSPF router-id |
| Loopback SW1        | 2.2.2.2/32      | OSPF router-id |

## Routing

- **OSPF area 0** between R1 and SW1 so the SVIs are reachable and you can show a
  dynamic routing protocol (not just static). Keep it simple: one area.
- **NAT/PAT** on R1 so all internal zones share the WAN address — classic edge design.

## Why a Raspberry Pi for defence?

- It is **real hardware on the real home network**, not another VM — recruiters
  like that you can monitor live traffic, not just lab traffic.
- It runs **Suricata** (IDS/IPS) + **nftables** (firewall) + a **Docker
  observability stack** (Loki/Promtail/Grafana) comfortably on a Pi 4 (2GB+).
- Two deployment options:
  1. **Inline gateway** — the Pi is the home LAN's gateway, so all traffic flows
     *through* it (IPS mode possible). Strongest demo.
  2. **SPAN/mirror (IDS only)** — mirror a port on your home router/switch into
     the Pi's NIC. Zero risk to home connectivity. Easiest to start with.

Start with option 2 (IDS, read-only). Move to option 1 once comfortable.

## Data flow for detection

```
traffic → Suricata → eve.json (JSON events) → Promtail → Loki → Grafana
                         │
                         └── alerts, flows, DNS, TLS, HTTP metadata
```

Grafana queries Loki with LogQL to build live panels: alerts over time, top
attacker IPs, alert signatures, DNS query-length anomalies (tunnel detection).

## Hardware / software checklist

**Laptop (8GB+ RAM recommended):**
- GNS3 or EVE-NG
- A Cisco image: IOSv / IOSvL2 (preferred) or IOU/IOL, or c7200 for the router
- Kali Linux VM (attacker)
- A lightweight Linux VM as the "target server" (Ubuntu Server)

**Raspberry Pi (Pi 4, 2GB+; Pi 5 ideal):**
- Raspberry Pi OS Lite (64-bit)
- Suricata, nftables, Docker + docker compose
- A second NIC (USB-Ethernet) if you run inline mode
