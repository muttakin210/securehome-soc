# Lab 3 — VLAN Segmentation + Inter-VLAN ACLs

## Objective
Split the network into zones (VLANs) and control exactly which zone can talk to
which — so a compromise in one zone can't spread.

## Topology
```
PC-USER (VLAN 10) ─ Fa0/1 ┐
PC-SERVER (VLAN 20) ─ Fa0/2 ┤  L3 Switch (3560)
PC-IOT (VLAN 30) ─── Fa0/3 ┘
```
- **3560** multilayer switch (needs L3 for SVIs / inter-VLAN routing)
- 3 PCs; set their gateways to the SVI of their VLAN

| VLAN | Name | Subnet | Gateway (SVI) | PC IP |
|------|------|--------|---------------|-------|
| 10 | USERS | 10.10.10.0/24 | 10.10.10.1 | 10.10.10.10 |
| 20 | SERVERS | 10.10.20.0/24 | 10.10.20.1 | 10.10.20.10 |
| 30 | IOT | 10.10.30.0/24 | 10.10.30.1 | 10.10.30.10 |

## The attack
If everything is one flat network, an attacker who takes over the IoT gadget can
reach your servers directly (**lateral movement**). Segmentation + ACLs stop that.

## Config (paste on the 3560)
```
enable
configure terminal
ip routing                         ! turn on L3 switching
!
vlan 10
 name USERS
vlan 20
 name SERVERS
vlan 30
 name IOT
exit
!
! access ports
interface fa0/1
 switchport mode access
 switchport access vlan 10
interface fa0/2
 switchport mode access
 switchport access vlan 20
interface fa0/3
 switchport mode access
 switchport access vlan 30
exit
!
! SVIs = the gateways
interface vlan 10
 ip address 10.10.10.1 255.255.255.0
interface vlan 20
 ip address 10.10.20.1 255.255.255.0
interface vlan 30
 ip address 10.10.30.1 255.255.255.0
exit
!
! ---- Segmentation policy ----
! IoT may NOT reach any internal zone; USERS may reach SERVERS on web/ssh only.
ip access-list extended IOT-IN
 deny ip 10.10.30.0 0.0.0.255 10.10.0.0 0.0.255.255
 permit ip 10.10.30.0 0.0.0.255 any
!
ip access-list extended USERS-IN
 permit tcp 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 eq 22
 permit tcp 10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255 eq 80
 deny   ip  10.10.10.0 0.0.0.255 10.10.20.0 0.0.0.255
 permit ip  10.10.10.0 0.0.0.255 any
exit
!
interface vlan 30
 ip access-group IOT-IN in
interface vlan 10
 ip access-group USERS-IN in
exit
end
write memory
```

## Verify
```
show ip interface brief            ! SVIs up
show vlan brief                    ! ports in the right VLANs
show access-lists                  ! hit counters
```
Test from each PC (Desktop → Command Prompt):
- `ping 10.10.20.10` from **IoT** PC → **fails** (ACL blocks it) ✅
- `ping 10.10.20.10` from **USERS** PC → ICMP blocked but port 80/22 allowed
  (test with the Web Browser to the server) ✅

## ACL rules to remember (interview)
- Processed **top-down**, first match wins → specific rules first, `permit ... any` last.
- Implicit **deny any** at the end of every ACL.
- Extended ACLs filter on source+dest+port; place them **close to the source**.

## Interview
> "I put users, servers, and untrusted IoT in separate VLANs and enforced an ACL
> on each SVI. IoT can reach the internet but nothing internal, and users reach
> servers only on the ports they need. That's segmentation — it shrinks the blast
> radius if any one device is compromised."
