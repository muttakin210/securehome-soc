# SecureHome SOC 🛡️

A home-built, segmented network + Security Operations Center (SOC) that lets me
**attack, detect, and defend** across all layers of the OSI model — built on a
single laptop (virtual Cisco lab) and a Raspberry Pi (live IDS + dashboards).

> **Why this project exists:** Most "home lab" projects stop at "I configured a
> router." This one closes the full loop a real Network Security engineer works
> in: design a segmented network → launch real attacks → detect them with an
> IDS → visualise and respond. Every alert in the dashboard is explained down to
> the packet (TCP flags, OSI layer, protocol).

---

## 🎯 What this demonstrates

| Area | Skills shown |
|------|--------------|
| **Networking** | VLAN segmentation, inter-VLAN routing, OSPF, NAT, ACLs (Cisco IOS) |
| **OSI / TCP-IP** | Packet-level analysis of each attack (L2 → L7), TCP 3-way handshake, DNS internals |
| **Security (defence)** | Suricata IDS/IPS, firewall policy (nftables), network segmentation, SIEM dashboards |
| **Security (offence)** | Recon (Nmap), brute-force (Hydra), DNS tunneling (iodine/dnstt) |
| **Linux / DevOps** | Raspberry Pi hardening, shell automation, Docker observability stack |
| **Communication** | Clean docs, network diagram, 3-minute demo video |

---

## 🗺️ Architecture

```
                    INTERNET
                       │
        ┌──────────────┴──────────────┐
        │   Raspberry Pi (DEFENSE)     │
        │   • nftables firewall        │
        │   • Suricata IDS/IPS         │
        │   • Promtail → Loki → Grafana│
        └──────────────┬──────────────┘
                       │  (all home traffic flows through / is mirrored here)
        ┌──────────────┴──────────────┐
        │  Edge Router  R1  (NAT/WAN)  │   ← laptop, GNS3/EVE-NG
        └──────────────┬──────────────┘
                       │ 802.1Q trunk
        ┌──────────────┴──────────────┐
        │   L3 Core Switch  SW1        │   SVIs + inter-VLAN ACLs
        └───┬───────────┬───────────┬──┘
            │           │           │
        VLAN 10     VLAN 20     VLAN 30
        USERS       SERVERS       IoT
     10.10.10.0/24 10.10.20.0/24 10.10.30.0/24
            │           │           │
        [Kali =      [Target      [IoT device
        attacker]     server]      = untrusted]
```

See [`docs/architecture.md`](docs/architecture.md) for IP plan, VLAN table, and
the full topology diagram ([`docs/topology.md`](docs/topology.md)).

---

## 📁 Repository layout

```
securehome-soc/
├── README.md                  ← you are here
├── docs/
│   ├── architecture.md        ← IP plan, VLANs, design rationale
│   ├── topology.md            ← network diagram (Mermaid)
│   ├── demo-playbook.md       ← the exact 3-minute live demo script
│   ├── interview-prep.md      ← Q&A recruiters will ask about this project
│   └── resume-bullets.md      ← copy-paste resume/LinkedIn lines
├── cisco/
│   ├── R1-edge-router.cfg     ← NAT + WAN edge
│   ├── SW1-core-L3.cfg        ← SVIs, inter-VLAN routing, ACLs
│   └── SW2-access.cfg         ← access-port switch
├── raspberry-pi/
│   ├── setup.sh               ← one-shot Suricata + firewall install
│   ├── firewall/nftables.conf ← segmentation + egress policy
│   └── suricata/custom.rules  ← scan / brute-force / DNS-tunnel detection
├── dashboards/
│   ├── docker-compose.yml     ← Loki + Promtail + Grafana (runs on the Pi)
│   ├── promtail-config.yml    ← ships Suricata eve.json into Loki
│   └── grafana-dashboard.json ← import into Grafana for live alerts
└── attacks/
    ├── 01-recon-nmap.md
    ├── 02-ssh-bruteforce.md
    └── 03-dns-tunnel.md
```

---

## 🚀 Quick start

> **Already have VirtualBox VMs (Kali, Metasploitable, etc.)?** Skip GNS3 and run
> the whole attack→detect demo on your existing VMs — see
> [`docs/virtualbox-lab.md`](docs/virtualbox-lab.md).

1. **Laptop:** install [GNS3](https://gns3.com) (or EVE-NG). Build the topology
   in `docs/topology.md`, then paste the configs from `cisco/` into each device.
2. **Raspberry Pi:** flash Raspberry Pi OS Lite, then run:
   ```bash
   sudo bash raspberry-pi/setup.sh
   ```
3. **Dashboards:** on the Pi, `cd dashboards && docker compose up -d`, open
   `http://<pi-ip>:3000`, import `grafana-dashboard.json`.
4. **Run the demo:** follow [`docs/demo-playbook.md`](docs/demo-playbook.md) —
   launch each attack from Kali and watch the dashboard light up.

---

## 🎬 The demo (what I show in an interview)

1. Show the segmented network — prove IoT VLAN **cannot** reach the Servers VLAN (ACL).
2. From Kali, run an **Nmap scan** → Suricata fires a scan alert → Grafana panel spikes.
3. Run an **SSH brute-force** → threshold rule fires → explain the TCP handshake flood.
4. Run a **DNS tunnel** → custom rule detects abnormal DNS → explain how data hides in DNS.
5. Walk through one alert in Wireshark, layer by layer (OSI L2→L7).

Full word-for-word script: [`docs/demo-playbook.md`](docs/demo-playbook.md).

---

## ⚠️ Ethics & scope

Every attack in this repo is run **only** inside my own isolated lab network
against **my own** VMs. These techniques are for learning defensive detection.
Never run them against systems you do not own or have written permission to test.

---

## 📚 Learn alongside this project

- [Cisco Security — hands-on lab course](learn/cisco-security/README.md) — 5
  progressive Packet Tracer labs: port security, DHCP snooping + DAI, VLAN/ACL
  segmentation, router ACL/NAT, and SSH/AAA hardening.
- [WiFi Security — hands-on guide](learn/wifi-security/README.md) — WPA2 handshake
  capture + crack (aircrack-ng/hashcat), analysing it in Wireshark, WPS/evil-twin,
  and how to harden your own WiFi. Own-network / authorized testing only.
- [University Campus Network — secure design](projects/university-network/README.md)
  — a full 3-tier campus network (Core/Distribution/Access, 9 VLANs, HSRP +
  EtherChannel redundancy, ASA firewall) with ready-to-paste Cisco configs and
  layered security (segmentation ACLs, port security, DHCP snooping + DAI).

## 🧰 Built with

Cisco IOS · GNS3/EVE-NG · Kali Linux · Raspberry Pi OS · Suricata · nftables ·
Loki · Promtail · Grafana · Docker · Wireshark
