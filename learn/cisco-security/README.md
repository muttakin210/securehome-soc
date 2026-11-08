# Cisco Security — Hands-on Lab Course 🖧🔒

A progressive, do-it-yourself course to learn **network security on Cisco IOS**,
built for **Cisco Packet Tracer** (free; you already have it installed).

Each lab follows the same shape:
1. **Objective** — the one skill you'll walk away with
2. **Topology** — what to drag onto the Packet Tracer canvas
3. **The attack** — what a bad actor does if this control is missing
4. **Config** — the exact Cisco commands (the solution)
5. **Verify** — how to prove it works
6. **Interview** — how to explain it

Do them in order — each builds on the last.

| # | Lab | Skill | Stops this attack |
|---|-----|-------|-------------------|
| 1 | [Port Security](lab1-port-security.md) | Lock switch ports to known MACs | MAC flooding, rogue devices |
| 2 | [DHCP Snooping + DAI](lab2-dhcp-snooping-dai.md) | Trust only the real DHCP server | Rogue DHCP, ARP spoofing / MITM |
| 3 | [VLAN + ACL segmentation](lab3-vlan-acl.md) | Separate zones, control traffic | Lateral movement after a breach |
| 4 | [Router ACL + NAT](lab4-router-acl-nat.md) | Filter at the perimeter | Unwanted inbound, scanning |
| 5 | [Hardening: SSH + AAA](lab5-hardening-aaa-ssh.md) | Secure device access | Password sniffing, unauthorized admin |

## How to use Packet Tracer for these

1. Open Packet Tracer → drag the devices from the lab's **Topology** onto the canvas.
2. Connect them (use **Copper Straight-Through** for PC↔switch and switch↔router;
   **Copper Cross-Over** switch↔switch).
3. Click a device → **CLI** tab → press Enter → `enable` → `configure terminal`,
   then paste the lab's config.
4. Run the **Verify** steps. Save with `end` then `write memory`.

> Tip: switch models — use **2960** for L2 labs (port security, DHCP snooping,
> DAI) and **3560**/**3650** when you need L3 switching (SVIs, inter-VLAN).
> Router — **2911** (ISR) for ACL/NAT/SSH/AAA.

## The theory behind it (CIA + defense in depth)

- **Confidentiality** — only the right people/devices see the data (SSH not Telnet, segmentation).
- **Integrity** — data isn't tampered with in transit (DAI stops ARP spoofing / MITM).
- **Availability** — the network keeps running (port security + BPDU guard stop floods/loops).
- **Defense in depth** — layers: L2 hardening → segmentation → perimeter ACL → secure management. No single control is enough; you stack them. These 5 labs are those layers.

## Where this takes you (job path)

- **Certs:** CompTIA **Security+** (foundations) → Cisco **CCNA** (covers labs 1–5) → **CCNP Security**.
- **Portfolio:** screenshot each working lab, write 1–2 lines, and you have a
  "Cisco network security lab" project to show — just like the SOC project in
  this repo.

> ⚠️ All attacks here are performed inside your own Packet Tracer simulation.
