# University Campus Network — Design + Secure Configuration 🎓🖧🔒

A full **3-tier campus network** (Core → Distribution → Access) for a university
with 6 faculties, an admin block, a server farm, and a management network —
configured end to end **with network security** (segmentation, HSRP + EtherChannel
redundancy, L2 hardening, ACLs, and an ASA firewall at the edge).

Build it in **Cisco Packet Tracer** (or real gear). Paste the configs from
[`configs/`](configs/) into each device in the build order below.

---

## 1. Architecture

```
                         INTERNET
                            │
                     ┌──────┴──────┐
                     │  R1  Edge    │  NAT/PAT + ISP default route
                     └──────┬──────┘
                     ┌──────┴──────┐
                     │  ASA  Firewall │  stateful, security levels, ACLs
                     └──────┬──────┘
             ┌──────────────┴──────────────┐
        ┌────┴────┐  Po1 (trunk)      ┌────┴────┐
        │ CORE-SW1│══════════════════ │ CORE-SW2│   L3 switches:
        │ (active)│  inter-VLAN + HSRP │(standby)│   SVIs, HSRP, DHCP
        └────┬────┘                    └────┬────┘
   redundant │  EtherChannel trunks to both cores │
        ┌────┴───────────┬───────────┬──────┴─────┐
     D-SW1   D-SW2   D-SW3   D-SW4   D-SW5   D-SW6   (distribution)
       │       │       │       │       │       │
   [faculty access switches: port security, DHCP snooping, DAI]
   Science  Eng    Business  Law   Education  Arts
   VLAN20  VLAN30  VLAN40  VLAN50  VLAN60   VLAN70

   Admin block = VLAN 10   Servers = VLAN 100   Management = VLAN 99
```

**Design principles**
- **Hierarchy:** access = connect endpoints + L2 security; distribution = aggregate
  + redundancy; core = fast L3 inter-VLAN routing + edge.
- **Redundancy:** every distribution switch dual-homes to **both** cores via
  **EtherChannel**; the two cores run **HSRP** so each VLAN has a redundant
  gateway; **Rapid-PVST+** with the core as root prevents loops.
- **Segmentation:** every faculty / block is its own VLAN; a faculty **cannot**
  reach another faculty or the servers except through explicitly permitted ports.
- **Defense in depth:** ASA firewall → core ACLs (segmentation) → access-layer L2
  hardening → secure management plane (SSH/AAA, VLAN 99).

---

## 2. VLAN & IP plan

| VLAN | Name | Subnet | Gateway (HSRP VIP) | CORE-SW1 SVI | CORE-SW2 SVI | Used by |
|------|------|--------|--------------------|--------------|--------------|---------|
| 10 | ADMIN | 192.168.10.0/24 | .1 | .2 | .3 | Admin, Registrar, HR, Finance |
| 20 | SCIENCE | 192.168.20.0/24 | .1 | .2 | .3 | Faculty of Science |
| 30 | ENGINEERING | 192.168.30.0/24 | .1 | .2 | .3 | Faculty of Engineering |
| 40 | BUSINESS | 192.168.40.0/24 | .1 | .2 | .3 | Faculty of Business |
| 50 | LAW | 192.168.50.0/24 | .1 | .2 | .3 | Faculty of Law |
| 60 | EDUCATION | 192.168.60.0/24 | .1 | .2 | .3 | Faculty of Education |
| 70 | ARTS | 192.168.70.0/24 | .1 | .2 | .3 | Faculty of Arts |
| 99 | MGMT | 192.168.99.0/24 | .1 | .2 | .3 | Switch/router management only |
| 100 | SERVER | 192.168.100.0/24 | .1 | .2 | .3 | Web, DB, Email, File, DNS servers |

**Transit links (routed /30s)**
| Link | Subnet | Addresses |
|------|--------|-----------|
| R1 ↔ ISP | DHCP/public | R1 Gi0/0 |
| R1 ↔ ASA outside | 203.0.113.0/30 | R1 .1, ASA .2 |
| ASA inside ↔ Core | 192.168.200.0/30 | ASA .1, Core-VIP .2 |

> HSRP priority: CORE-SW1 = 110 (active + preempt), CORE-SW2 = 100 (standby).
> For load-balancing, make SW2 active for odd VLANs (note in the core configs).

---

## 3. Security design (what protects what)

| Layer | Control | Stops |
|-------|---------|-------|
| **Edge** | ASA stateful firewall, security levels, outbound-only by default | Inbound attacks, scanning |
| **Edge** | R1 NAT/PAT + anti-spoof ACL | Hides inside, blocks spoofed sources |
| **Core** | Inter-VLAN **ACLs** (faculty isolation, server access control) | Lateral movement between faculties/to servers |
| **Core** | Management plane: SSH/AAA, VLAN 99 restricted | Unauthorized admin, clear-text mgmt |
| **Access** | **Port security** (sticky MAC, violation shutdown) | Rogue devices, MAC flooding |
| **Access** | **DHCP snooping + DAI** | Rogue DHCP, ARP spoofing / MITM |
| **Access** | **BPDU Guard + PortFast**, unused ports shut | Rogue switch / STP attack |
| **All** | `service password-encryption`, banners, timeouts | Shoulder-surfing, stored secrets |

**Segmentation policy (enforced by ACLs on the core SVIs)**
- Faculties (20–70): reach the **Internet** and specific **servers** (DNS, Web,
  Email, File) — **not** each other, **not** Admin, **not** Management.
- Admin (10): reach servers + manage via VLAN 99; not reachable from faculties.
- Servers (100): reply to clients; do not initiate into user VLANs.
- Management (99): only admins/NMS; reachable only from Admin + itself.

---

## 4. Build order (paste configs in this order)

1. **Core switches** — [`configs/core-sw1.txt`](configs/core-sw1.txt),
   [`configs/core-sw2.txt`](configs/core-sw2.txt) (VLANs, SVIs, HSRP, Po1, DHCP, ACLs).
2. **Distribution** — [`configs/distribution-template.txt`](configs/distribution-template.txt)
   (one per D-SW1…6; EtherChannel to both cores, trunks down).
3. **Access** — [`configs/access-template.txt`](configs/access-template.txt)
   (one per faculty/department switch; set the VLAN from the table).
4. **Admin / Server / Mgmt** — [`configs/admin-server-mgmt.txt`](configs/admin-server-mgmt.txt).
5. **Edge** — [`configs/edge-router-R1.txt`](configs/edge-router-R1.txt) and
   [`configs/asa-firewall.txt`](configs/asa-firewall.txt).
6. **Verify** — see the checklist at the end of each config.

---

## 5. Verification quick list
```
show etherchannel summary        ! Po1 = (SU), bundled
show standby brief               ! HSRP: one Active, one Standby per VLAN
show ip route                    ! connected SVIs + default via ASA
show vlan brief                  ! ports in correct VLANs
show spanning-tree root          ! core is the root bridge
show port-security               ! access ports secured
show ip dhcp snooping            ! snooping on, server port trusted
show access-lists                ! ACL hit counters during tests
```

Test: a Science PC should reach the Web server and the Internet, but a ping from
**Science → Law** or **Science → Admin** must **fail** (ACL). Unplug one core and
traffic should keep flowing (HSRP failover).

> ⚠️ Lab/educational design. Build and test it in your own Packet Tracer file —
> **save often** (File → Save) so a session timeout can't lose your work.
