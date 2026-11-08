# Build Guide — University Network in Packet Tracer 🛠️

Follow this to build the whole project **phase by phase**. After each phase,
**File → Save** (a `.pkt` file) so a session timeout can't lose your work, and
run the phase's verify step before moving on.

> **Simplified-but-faithful device set.** The original diagram shows ~3 access
> switches per faculty. For a buildable lab, use **1 access switch per faculty**
> (same VLANs, same design). Add more access switches later the same way.

---

## Device inventory (place these first)

| Qty | Device | Model | Names |
|----:|--------|-------|-------|
| 1 | Router | 2911 | R1 |
| 1 | Firewall | ASA 5506-X | ASA |
| 2 | Multilayer switch | 3560-24PS | CORE-SW1, CORE-SW2 |
| 6 | Multilayer/L2 switch | 3560-24PS (or 2960) | D-SW1 … D-SW6 |
| 6 | Switch | 2960-24TT | AC-SCI, AC-ENG, AC-BUS, AC-LAW, AC-EDU, AC-ART |
| 3 | Switch | 2960-24TT | SW-ADMIN, SW-SERVER, SW-MGMT |
| ~ | PCs / Servers | PC-PT / Server-PT | 2–3 PCs per faculty, 5 servers, admin PCs |
| 1 | Cloud/Server | — | "Internet" |

> Tip: place the core in the middle, distribution in a row below, access below
> that, edge (R1+ASA) at the top. Keeps cabling readable.

---

## Cable map (Copper Straight-Through unless noted)

**Edge / Core**
| From | Port | To | Port |
|------|------|----|------|
| R1 | Gi0/0 | Internet (cloud) | — |
| R1 | Gi0/1 | ASA | Gi1/1 (outside) |
| ASA | Gi1/2 (inside) | CORE-SW1 | Gi0/9 |
| CORE-SW1 | Gi0/1 | CORE-SW2 | Gi0/1 | *(Po1 — cross-over)* |
| CORE-SW1 | Gi0/2 | CORE-SW2 | Gi0/2 | *(Po1 — cross-over)* |

**Cores ↔ Distribution** (each D-SW dual-homes to BOTH cores — cross-over)
| D-SW | to CORE-SW1 | to CORE-SW2 |
|------|-------------|-------------|
| D-SW1 | CORE-SW1 Gi0/3 ↔ D-SW1 Gi0/1 | CORE-SW2 Gi0/3 ↔ D-SW1 Gi0/2 |
| D-SW2 | CORE-SW1 Gi0/4 ↔ D-SW2 Gi0/1 | CORE-SW2 Gi0/4 ↔ D-SW2 Gi0/2 |
| D-SW3 | CORE-SW1 Gi0/5 ↔ D-SW3 Gi0/1 | CORE-SW2 Gi0/5 ↔ D-SW3 Gi0/2 |
| D-SW4 | CORE-SW1 Gi0/6 ↔ D-SW4 Gi0/1 | CORE-SW2 Gi0/6 ↔ D-SW4 Gi0/2 |
| D-SW5 | CORE-SW1 Gi0/7 ↔ D-SW5 Gi0/1 | CORE-SW2 Gi0/7 ↔ D-SW5 Gi0/2 |
| D-SW6 | CORE-SW1 Gi0/8 ↔ D-SW6 Gi0/1 | CORE-SW2 Gi0/8 ↔ D-SW6 Gi0/2 |

**Distribution ↔ Access** (cross-over) and **Access ↔ PCs** (straight-through)
| Faculty | D-SW | Access SW | VLAN |
|---------|------|-----------|------|
| Science | D-SW1 Fa0/1 ↔ AC-SCI Gi0/1 | AC-SCI Fa0/1–3 → PCs | 20 |
| Engineering | D-SW2 Fa0/1 ↔ AC-ENG Gi0/1 | AC-ENG Fa0/1–3 → PCs | 30 |
| Business | D-SW3 Fa0/1 ↔ AC-BUS Gi0/1 | AC-BUS Fa0/1–3 → PCs | 40 |
| Law | D-SW4 Fa0/1 ↔ AC-LAW Gi0/1 | AC-LAW Fa0/1–3 → PCs | 50 |
| Education | D-SW5 Fa0/1 ↔ AC-EDU Gi0/1 | AC-EDU Fa0/1–3 → PCs | 60 |
| Arts | D-SW6 Fa0/1 ↔ AC-ART Gi0/1 | AC-ART Fa0/1–3 → PCs | 70 |

**Admin / Server / Mgmt** (connect to the cores — cross-over)
| From | Port | To | Port | VLAN |
|------|------|----|------|------|
| SW-ADMIN | Gi0/1 | CORE-SW1 | Gi0/10 | 10 |
| SW-SERVER | Gi0/1 | CORE-SW1 | Gi0/11 | 100 |
| SW-MGMT | Gi0/1 | CORE-SW1 | Gi0/12 | 99 |
| Admin PCs | Fa | SW-ADMIN Fa0/1–4 | — | 10 |
| 5 Servers | Fa | SW-SERVER Fa0/1–5 | — | 100 |

> In Packet Tracer the **"Automatically Choose Connection Type"** cable (gold
> lightning) picks the right cable for you — use it and skip the straight/cross
> decision.

---

## Phased build (save after each phase ✅)

### Phase 1 — Core (the brain)
Place CORE-SW1, CORE-SW2; cable Po1 between them. Paste
[`configs/core-sw1.txt`](configs/core-sw1.txt) and
[`configs/core-sw2.txt`](configs/core-sw2.txt).
**Verify:** `show etherchannel summary` → Po1 = `SU`; `show standby brief` →
SW1 Active, SW2 Standby. **Save.**

### Phase 2 — Distribution
Place D-SW1…6; cable each to both cores. Paste
[`configs/distribution-template.txt`](configs/distribution-template.txt) into each
(change hostname, faculty VLAN, and mgmt IP per switch).
**Verify:** `show spanning-tree` → one uplink FWD, one BLK. **Save.**

### Phase 3 — Access + PCs
Place the 6 faculty access switches; cable to distribution and add PCs. Paste
[`configs/access-template.txt`](configs/access-template.txt) into each (set the
faculty VLAN). Set PCs to **DHCP**.
**Verify:** each PC gets an IP in its VLAN; `show port-security`. **Save.**

### Phase 4 — Admin / Server / Mgmt
Place SW-ADMIN, SW-SERVER, SW-MGMT; cable to CORE-SW1; add admin PCs + 5 servers.
Paste the three blocks from
[`configs/admin-server-mgmt.txt`](configs/admin-server-mgmt.txt). Give servers the
**static IPs** listed there (Web .10, DB .20, Email .30, File .40, DNS .50).
**Verify:** a faculty PC can reach the DNS/Web server. **Save.**

### Phase 5 — Edge (Internet)
Place R1 + ASA + the "Internet" device; cable per the map. Paste
[`configs/edge-router-R1.txt`](configs/edge-router-R1.txt) and
[`configs/asa-firewall.txt`](configs/asa-firewall.txt).
**Verify:** a faculty PC can reach the Internet; `show ip nat translations` on R1.
**Save.**

### Phase 6 — Security tests (the portfolio proof)
- **Segmentation:** from a **Science** PC, `ping` a **Law** or **Admin** PC →
  must **fail** (ACL). Ping the **Web server** → must **work**.
- **Redundancy:** shut down CORE-SW1 (or pull its cable) → PCs keep reaching the
  gateway/Internet (HSRP failover). `show standby brief` on CORE-SW2 now Active.
- **Port security:** move a PC to another secured port with a new MAC → port goes
  **err-disabled**.
Screenshot each — that's your evidence. **Save.**

---

## If you get stuck
Send me the **exact command + the error/output** (or a screenshot) and which
phase you're on. Common gotchas:
- `%EtherChannel ... not bundling` → both ends must match (mode active/active,
  same allowed VLANs).
- No HSRP Active → check the SVI IPs (.2 / .3) and `standby ip` matches on both.
- PC gets no DHCP → is the access-switch uplink `ip dhcp snooping trust`? Is the
  core's `ip helper-address` / DHCP pool correct for that VLAN?
- Faculty can't reach a server → check the port is permitted in `FACULTY-IN`.
