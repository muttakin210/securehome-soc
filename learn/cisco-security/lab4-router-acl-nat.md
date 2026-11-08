# Lab 4 — Router ACL + NAT (perimeter)

## Objective
At the edge router, hide the internal network behind one public IP (NAT/PAT) and
filter what's allowed in/out with ACLs.

## Topology
```
Inside LAN ── Gi0/0 [Router 2911] Gi0/1 ── "Internet" (a server or cloud)
10.0.0.0/24                         203.0.113.1/30
```
- **2911** router
- Inside: a switch + a PC (10.0.0.10/24, gateway 10.0.0.1)
- Outside: a Server acting as the internet host (203.0.113.2), e.g. a web server

## The attack
A flat, unfiltered edge lets attackers scan and reach internal hosts directly,
and exposes internal IPs. NAT hides the inside; ACLs drop unwanted traffic.

## Config (paste on the router)
```
enable
configure terminal
!
interface gigabitEthernet0/0
 description INSIDE
 ip address 10.0.0.1 255.255.255.0
 ip nat inside
 no shutdown
!
interface gigabitEthernet0/1
 description OUTSIDE
 ip address 203.0.113.1 255.255.255.252
 ip nat outside
 no shutdown
exit
!
! default route to the internet
ip route 0.0.0.0 0.0.0.0 203.0.113.2
!
! ---- NAT / PAT: hide 10.0.0.0/24 behind the outside interface ----
ip access-list standard NAT-INSIDE
 permit 10.0.0.0 0.0.0.255
ip nat inside source list NAT-INSIDE interface gigabitEthernet0/1 overload
!
! ---- Inbound filter on OUTSIDE: allow only replies + block spoofing ----
ip access-list extended OUTSIDE-IN
 permit tcp any any established               ! let return traffic back in
 permit icmp any any echo-reply
 deny   ip 10.0.0.0 0.0.0.255 any             ! anti-spoof: no "inside" src from outside
 deny   ip any any
!
interface gigabitEthernet0/1
 ip access-group OUTSIDE-IN in
exit
end
write memory
```

## Verify
```
show ip nat translations           ! after the PC browses out
show ip nat statistics
show access-lists OUTSIDE-IN        ! hit counts
```
Test:
- From inside PC, browse the outside web server → works; `show ip nat
  translations` shows the PAT entry (one public IP, many ports).
- From the outside host, try to start a connection **into** the PC → blocked by
  `OUTSIDE-IN`.

## Key ideas (interview)
- **NAT vs PAT:** NAT = 1:1 address mapping; **PAT (overload)** = many inside
  hosts share one public IP, told apart by port number.
- **`established`** permits only packets that are part of an existing session
  (ACK/RST set) — a simple stateful-ish inbound filter.
- **Anti-spoofing ACL:** drop inbound packets claiming an internal source IP.

## Interview
> "The edge router does PAT so the whole inside network shares one public IP, and
> an inbound ACL on the outside interface only lets established return traffic
> back in, drops spoofed internal sources, and denies everything else. That's the
> perimeter layer of defense in depth."
