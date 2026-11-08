# Lab 5 — Device Hardening: SSH + AAA + STP protection

## Objective
Secure how you *manage* the device itself: encrypted admin access (SSH not
Telnet), real logins (AAA), and protect the spanning tree from rogue switches.

## Topology
Any switch or router from the earlier labs + one PC to SSH from.
Give the device a management IP (SVI on a switch, or an interface on a router),
e.g. `10.0.0.1/24`, and the PC `10.0.0.10/24`.

## The attack
- **Telnet sends everything in clear text** — a sniffer grabs the admin password.
- **Default/no AAA** — shared passwords, no accountability.
- **STP attack** — a rogue switch claims to be root bridge and reroutes traffic
  through itself.

## Config (paste on the device)
```
enable
configure terminal
!
hostname SEC-SW
ip domain-name lab.local
!
! ---- strong local admin + AAA (local database) ----
username admin privilege 15 secret Str0ng-Admin!
enable secret Str0ng-Enable!
aaa new-model
aaa authentication login default local
aaa authorization exec default local
!
! ---- SSH v2 only (generates the crypto key) ----
crypto key generate rsa modulus 2048
ip ssh version 2
ip ssh time-out 60
ip ssh authentication-retries 3
!
line vty 0 4
 transport input ssh          ! SSH only — Telnet disabled
 login authentication default
 exec-timeout 5 0
exit
line con 0
 login authentication default
 exec-timeout 5 0
exit
!
! ---- general hardening ----
service password-encryption
no ip http server
no cdp run                    ! (optional) stop leaking device info
banner motd #Authorized access only. Activity is logged.#
!
! ---- protect spanning tree on access ports ----
interface range fa0/1 - 24
 spanning-tree portfast
 spanning-tree bpduguard enable
exit
end
write memory
```

## Verify
```
show ip ssh                   ! SSH v2 enabled
show run | include transport  ! transport input ssh
show users                    ! who is logged in
show spanning-tree summary    ! BPDU guard active
```
From the PC's **Command Prompt** (Packet Tracer):
```
ssh -l admin 10.0.0.1         ! prompts for password, encrypted session
telnet 10.0.0.1               ! should be refused
```

## Why each piece (interview)
- **SSH vs Telnet:** SSH encrypts the management session; Telnet is clear text.
- **AAA:** Authentication (who are you), Authorization (what may you do),
  Accounting (what did you do). Here it's local; in production it's RADIUS/TACACS+.
- **`service password-encryption`** hides passwords in `show run` (weak type 7 —
  real secrets use `secret` = type 8/9).
- **BPDU Guard + PortFast** on access ports err-disable any port that suddenly
  sends BPDUs — i.e. someone plugged in a rogue switch trying an STP attack.

## Interview
> "I disable Telnet and allow only SSHv2 with AAA logins and session timeouts, so
> management traffic is encrypted and every admin is authenticated. I add a login
> banner, encrypt stored passwords, and put BPDU Guard on access ports so a rogue
> switch can't hijack the spanning tree. That secures the control/management plane."

---

## 🎉 Course done
You've now built the five defense-in-depth layers:
**L2 hardening (1) → integrity/anti-MITM (2) → segmentation (3) → perimeter (4) →
secure management (5).** Screenshot each working lab, add a line to your CV, and
you have a second portfolio project next to the SOC one.
