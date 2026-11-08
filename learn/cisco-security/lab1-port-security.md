# Lab 1 — Switch Port Security

## Objective
Lock each switch access port so only a known device (MAC address) can use it.

## Topology
```
PC0 ──┐
PC1 ──┤ Switch (2960)
      └── (Gi0/3 left open for the "attacker")
```
- 2960 switch
- PC0 → FastEthernet0/1
- PC1 → FastEthernet0/2
- Give PC0/PC1 static IPs 10.0.0.10 / 10.0.0.11 /24 (Desktop → IP Configuration)

## The attack (why this matters)
Without port security, anyone can unplug a PC and plug in a laptop, or a hub, and
get straight onto the network. A **MAC-flooding** attack (e.g. `macof`) fills the
switch's MAC table so it starts behaving like a hub and floods frames to the
attacker — letting them sniff everyone's traffic.

## Config (paste on the switch)
```
enable
configure terminal
!
interface range fa0/1 - 2
 switchport mode access
 switchport port-security
 switchport port-security maximum 1
 switchport port-security mac-address sticky
 switchport port-security violation shutdown
exit
!
! disable every unused port
interface range fa0/3 - 24
 shutdown
exit
!
end
write memory
```
- **maximum 1** — only one MAC per port.
- **sticky** — the switch learns the current MAC and saves it to the config.
- **violation shutdown** — a second/unknown MAC err-disables the port.

## Verify
```
show port-security
show port-security address          ! see the learned "sticky" MACs
show port-security interface fa0/1
```
Now **test the attack**: move PC1's cable to Fa0/1 (or add PC2 to Fa0/3 and
enable it). The port should go **err-disabled**:
```
show interface fa0/1 status         ! -> err-disabled
```
Re-enable after fixing: `shutdown` then `no shutdown` on the port.

## Violation modes (know the difference — common interview Q)
| Mode | Drops bad frames | Logs/SNMP | Shuts the port |
|------|:----------------:|:---------:|:--------------:|
| protect  | ✅ | ❌ | ❌ |
| restrict | ✅ | ✅ | ❌ |
| shutdown | ✅ | ✅ | ✅ (err-disabled) |

## Interview
> "I lock each access port to one sticky MAC and err-disable on violation, and I
> shut all unused ports. That stops someone swapping in a rogue device and stops
> MAC-flooding attacks that try to turn the switch into a hub to sniff traffic."
