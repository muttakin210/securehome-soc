# Network Topology

Build this exact topology in GNS3/EVE-NG. Device names match the config files in
[`../cisco/`](../cisco/).

```mermaid
graph TD
    NET([Internet / NAT cloud])
    PI["Raspberry Pi<br/>nftables + Suricata IDS<br/>Loki + Grafana"]
    R1["R1 — Edge Router<br/>NAT / PAT + OSPF<br/>Gi0/0 WAN, Gi0/1 trunk"]
    SW1["SW1 — L3 Core Switch<br/>SVIs 10/20/30/99<br/>Inter-VLAN ACLs + OSPF"]
    SW2["SW2 — L2 Access Switch<br/>access ports"]
    KALI["Kali Linux<br/>VLAN 10 USERS<br/>10.10.10.100<br/>(attacker)"]
    SRV["Ubuntu Server<br/>VLAN 20 SERVERS<br/>10.10.20.100<br/>(target: ssh/web/dns)"]
    IOT["IoT device<br/>VLAN 30 IoT<br/>10.10.30.100<br/>(untrusted)"]

    NET --- PI
    PI --- R1
    R1 -- "802.1Q trunk" --- SW1
    SW1 --- SW2
    SW2 --- KALI
    SW2 --- SRV
    SW2 --- IOT
```

## Interface map

| Device | Interface | Connects to | Role |
|--------|-----------|-------------|------|
| R1 | Gi0/0 | Internet cloud / Pi | WAN (NAT outside) |
| R1 | Gi0/1 | SW1 Gi0/1 | 802.1Q trunk (NAT inside) |
| SW1 | Gi0/1 | R1 Gi0/1 | trunk / OSPF |
| SW1 | Gi0/2 | SW2 Gi0/1 | trunk |
| SW1 | (SVIs) | — | VLAN 10/20/30/99 gateways |
| SW2 | Gi0/1 | SW1 Gi0/2 | trunk |
| SW2 | Gi0/2 | Kali | access VLAN 10 |
| SW2 | Gi0/3 | Ubuntu server | access VLAN 20 |
| SW2 | Gi0/4 | IoT device | access VLAN 30 |

## GNS3 image notes

- **SW1 / SW2:** use **IOSvL2** (vIOS-L2) for VLANs + L3 switching. If you only
  have IOU/IOL L2 images, that works too.
- **R1:** **IOSv** or a c7200 router image for NAT + OSPF.
- **Kali:** import the official Kali VMware/VirtualBox appliance, attach its NIC
  to the GNS3 cloud/the Kali node.
- If your laptop is low on RAM, you can collapse SW1+SW2 into a single L3 switch
  (router-on-a-stick alternative noted inside `cisco/SW1-core-L3.cfg`).
