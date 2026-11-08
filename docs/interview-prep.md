# Interview Prep — Questions recruiters will ask about this project

Answer out loud until these feel natural. The goal: when they say "walk me
through a project," you own the next 5 minutes.

## The 60-second pitch (memorise this)

> "I built SecureHome SOC — a segmented network on a laptop and a Raspberry Pi.
> The laptop runs a virtual Cisco network with three VLANs — users, servers, and
> untrusted IoT — with inter-VLAN ACLs and NAT. The Pi is the defence layer:
> nftables firewall plus Suricata IDS, feeding a Grafana dashboard. I then attack
> my own network — port scans, SSH brute force, and DNS tunneling — and show the
> IDS detecting each one in real time, and I respond by blocking the attacker at
> the firewall. It proves I understand networking end to end and can defend it."

## Networking questions

**Q: Explain the TCP 3-way handshake.**
SYN → SYN/ACK → ACK. Client sends SYN (sequence number), server replies SYN/ACK,
client ACKs. A SYN scan sends only the SYN and never finishes — that half-open
pattern is what my scan rule detects.

**Q: What's the difference between a Layer 2 and Layer 3 switch / VLAN routing?**
L2 switches forward by MAC within a VLAN (broadcast domain). To move between
VLANs you need L3 — an SVI on a L3 switch or router-on-a-stick. In my lab, SW1's
SVIs are the gateways and do inter-VLAN routing; ACLs on those SVIs enforce which
VLAN can talk to which.

**Q: Why segment a network?**
Blast radius. If the IoT device is compromised, segmentation stops it reaching
the servers. I prove it: ping from IoT to servers fails because of the ACL.

**Q: What is NAT/PAT?**
Translating private internal addresses to one public WAN address (PAT = overload,
many-to-one using ports). R1 does this so all three VLANs share the WAN IP.

**Q: OSPF vs static routing?**
OSPF is a dynamic link-state protocol — routers learn topology and converge
automatically. I used it between R1 and SW1 so the SVIs are reachable without
hand-maintaining routes.

## Security questions

**Q: IDS vs IPS?**
IDS detects and alerts (out of band / on a mirror). IPS sits inline and can
block. My Pi runs IDS mode by default; inline mode turns it into an IPS.

**Q: How does your IDS detect a port scan if one SYN is normal?**
Behaviour over time. A threshold rule counts SYNs per source in a window — 30 in
5 seconds is a scan, one SYN isn't. That's the difference between signature and
anomaly/threshold detection.

**Q: What is DNS tunneling and why is it dangerous?**
Encoding data inside DNS queries (long labels, TXT records) to bypass firewalls,
since UDP/53 is almost always allowed out. Port-based firewalls miss it; you have
to inspect DNS behaviour — query length, entropy, volume. My custom Suricata rule
flags oversized/high-volume DNS.

**Q: Walk me through responding to the brute-force alert.**
Detect (Suricata threshold rule) → identify source IP in Grafana → contain (add
to nftables blocklist / fail2ban) → recommend hardening (key auth, disable
password login). Detection + response.

**Q: Defence in depth — give examples from your lab.**
Segmentation (VLAN+ACL), firewall (nftables default-deny), IDS (Suricata), port
security + BPDU guard at L2, SSH hardening, and centralised logging/alerting.

## Curveballs

**Q: What would you improve / what's next (v2)?**
- Inline IPS mode to actively block, not just alert.
- fail2ban auto-blocking wired into nftables.
- ML-based DNS-tunnel scoring (name length + entropy) — my research direction.
- Add a web app to the servers VLAN and detect SQL injection / web attacks.
- Infrastructure-as-code: automate the whole build (Ansible / containerlab).

**Q: What was the hardest part?**
Be honest — e.g. getting Suricata to see the right traffic (SPAN vs inline), or
tuning thresholds so real scans fire but normal traffic doesn't (false positives).
Showing you understand false positives is a *plus*.

**Q: Did you follow a tutorial?**
"I used docs for each tool, but the design — the segmentation policy, the custom
rules, the attack-to-detection mapping — is mine. I can change any part live."
