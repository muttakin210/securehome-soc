# Build Order — 1-2 Week Checklist

Your chosen pace. Tick each box. Even 2-3 hours/day finishes this in ~12 days.

## Week 1 — build the network + defence

- [ ] **Day 1 — Lab install.** Install GNS3 (or EVE-NG) on the laptop. Import a
      Cisco IOSv + IOSvL2 image and a Kali VM. Flash Raspberry Pi OS Lite on the Pi.
- [ ] **Day 2 — Topology.** Build the diagram in [`topology.md`](topology.md).
      Paste `cisco/R1-edge-router.cfg`, `SW1-core-L3.cfg`, `SW2-access.cfg`.
      Verify: each VLAN host gets its gateway, can ping its own gateway.
- [ ] **Day 3 — Routing + internet.** Confirm OSPF neighbors up (`show ip ospf
      neighbor`), NAT works (`show ip nat translations`), VLAN hosts reach the internet.
- [ ] **Day 4 — Segmentation.** Apply the ACLs. **Prove** IoT → Servers is blocked
      and Users → Servers works only on allowed ports. Screenshot this.
- [ ] **Day 5 — Pi defence.** `sudo bash raspberry-pi/setup.sh`. Confirm Suricata
      runs (`systemctl status suricata`) and `nft list ruleset` shows the firewall.
- [ ] **Day 6 — See traffic.** Set up SPAN/mirror (or inline) so the Pi sees LAN
      traffic. Confirm `tail -f /var/log/suricata/eve.json` shows flow events.
- [ ] **Day 7 — Dashboards.** `cd dashboards && docker compose up -d`. Open
      Grafana, add the Loki datasource, import `grafana-dashboard.json`.

## Week 2 — attack, detect, package

- [ ] **Day 8 — Recon.** Run [`attacks/01-recon-nmap.md`](../attacks/01-recon-nmap.md).
      Confirm the scan alert appears in Grafana. Screenshot.
- [ ] **Day 9 — Brute force + response.** Run
      [`attacks/02-ssh-bruteforce.md`](../attacks/02-ssh-bruteforce.md), then block
      the attacker with nftables. Screenshot both.
- [ ] **Day 10 — DNS tunnel.** Run
      [`attacks/03-dns-tunnel.md`](../attacks/03-dns-tunnel.md). Confirm the custom
      rules fire. This is your headline screenshot.
- [ ] **Day 11 — Record.** Follow [`demo-playbook.md`](demo-playbook.md) and record
      the 3-minute video with OBS. Upload unlisted to YouTube.
- [ ] **Day 12 — Package.** Fill the real URLs into the README and
      [`resume-bullets.md`](resume-bullets.md). Push to GitHub (public). Post on
      LinkedIn with the video + 3 screenshots. Rehearse `interview-prep.md` aloud.

## "I'm stuck" quick checks

| Symptom | Check |
|---------|-------|
| VLAN host can't ping gateway | Is the access port in the right VLAN? Trunk allowing that VLAN? |
| No internet from a VLAN | OSPF neighbor up? NAT inside/outside on the right interfaces? |
| ACL blocks everything | Remember ACLs are top-down; `permit ip ... any` must be last |
| Suricata sees no traffic | Wrong `MON_IFACE`, or SPAN not mirroring; test with `tcpdump -i <iface>` |
| Grafana empty | Loki datasource URL = `http://loki:3100`? Promtail reading `/var/log/suricata`? |
| Alert won't fire | Lower the threshold temporarily to confirm the rule path, then restore |

## Minimum viable version (if you run low on time)

Skip SW2 (collapse into SW1), skip inline mode (use SPAN/IDS only), and demo just
**two** attacks (scan + DNS tunnel). You still show segmentation + detection +
the standout DNS-tunnel catch. That alone is interview-worthy.
