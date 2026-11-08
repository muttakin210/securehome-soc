# Lab 2 — DHCP Snooping + Dynamic ARP Inspection (DAI)

## Objective
Trust only the **real** DHCP server, and stop **ARP spoofing** (the classic
man-in-the-middle attack).

## Topology
```
DHCP Server ── Gi0/1 ┐
PC0 ──────────── Fa0/1 ┤ Switch (2960)
Attacker PC ──── Fa0/2 ┘   (will try rogue DHCP + ARP spoof)
```
- 2960 switch
- A **Server** (set it as a DHCP server: Services → DHCP → On, pool 10.0.0.0/24)
- PC0 and "Attacker" PC set to **DHCP** (Desktop → IP Configuration → DHCP)

## The attacks
1. **Rogue DHCP** — the attacker runs their own DHCP server and hands victims a
   fake gateway (themselves), so all traffic flows through the attacker.
2. **ARP spoofing / poisoning** — the attacker lies "I am the gateway" via forged
   ARP replies, becoming a **man-in-the-middle** and capturing/altering traffic.

## Config (paste on the switch)
```
enable
configure terminal
!
! ---- DHCP Snooping: only the port to the real server is "trusted" ----
ip dhcp snooping
ip dhcp snooping vlan 1
no ip dhcp snooping information option        ! PT-friendly
!
interface gigabitEthernet0/1
 description Link to REAL DHCP server
 ip dhcp snooping trust
exit
!
! client ports stay untrusted + rate-limited (stops DHCP starvation)
interface range fa0/1 - 2
 ip dhcp snooping limit rate 10
exit
!
! ---- Dynamic ARP Inspection: validate ARP against the snooping table ----
ip arp inspection vlan 1
interface gigabitEthernet0/1
 ip arp inspection trust
exit
!
end
write memory
```
**How it fits together:** DHCP snooping builds a table of *real* IP↔MAC↔port
bindings from legitimate DHCP leases. DAI then checks every ARP packet against
that table — forged ARP (the spoof) doesn't match, so it's dropped.

## Verify
```
show ip dhcp snooping
show ip dhcp snooping binding        ! the IP-MAC-port bindings
show ip arp inspection
show ip arp inspection statistics    ! watch "Dropped" rise during a spoof
```
- Have PC0 request DHCP → a binding appears.
- From the Attacker PC, try a rogue DHCP / forged ARP → it's blocked; untrusted
  DHCP-server replies on Fa0/2 are dropped.

## Interview
> "DHCP snooping marks only the server port as trusted and builds an IP-MAC-port
> binding table. Dynamic ARP Inspection uses that table to drop forged ARP
> replies, which kills ARP-spoofing man-in-the-middle attacks. Together they
> protect integrity at Layer 2."
