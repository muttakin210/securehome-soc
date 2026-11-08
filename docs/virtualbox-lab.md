# Running SecureHome SOC on Your VirtualBox Lab

This maps the SecureHome SOC demo onto the VMs you already have in VirtualBox,
so you get a **real** attack→detect demo without GNS3/Packet Tracer bridging.

## Your VMs (already built)

| VM | Role in this demo | Notes |
|----|-------------------|-------|
| **kali linux** | Attacker | eth0 = `192.168.1.4/24`, NAT Network `thesis1` |
| **metasploitable 2** | Vulnerable target | lots of open services (ftp/ssh/telnet/http/smb/mysql) |
| **dnslab-attacker / dnslab-victim / dnslab-gateway** | DNS-tunnel demo | Internal Network `dnslab` (your research lab) |

## Step 0 — Put attacker + target on the SAME network

Kali is on NAT Network `thesis1`. For Kali to attack Metasploitable, the target
must be on the **same** network. In VirtualBox (VM powered off):

`Settings → Network → Adapter 1 → Attached to: NAT Network → Name: thesis1`

Do this for **metasploitable 2**, then start it. (The dnslab VMs stay on their
own `dnslab` network for the DNS-tunnel part.)

> Tip: a NAT Network lets the VMs talk to each other and the internet, but keeps
> them isolated from your real home LAN — perfect and safe for attacks.

---

## Step 1 — Recon from Kali (find + map the target)

Open a terminal in Kali and run:

```bash
# 1. Confirm your own address
ip -br a

# 2. Discover other hosts on the lab network (finds Metasploitable)
nmap -sn 192.168.1.0/24

# 3. Full port + service scan of the target (replace TARGET with its IP)
nmap -sS -sV -p- 192.168.1.X
```

**Detection note:** this scan is what Suricata rule **SID 1000001** (SYN scan)
is built to catch. See Step 4 for where the IDS runs.

---

## Step 2 — SSH brute force

Metasploitable's default login is `msfadmin / msfadmin` — great for a safe demo.

```bash
printf 'root\nadmin\nmsfadmin\npassword\n123456\n' > wordlist.txt
hydra -l msfadmin -P wordlist.txt ssh://192.168.1.X -t 4
```

Triggers Suricata rule **SID 1000010** (SSH brute force). Respond by blocking the
source (Step 4).

---

## Step 3 — DNS tunneling (your research lab)

Use the `dnslab` VMs, which are already wired for this:

- **dnslab-gateway** — runs the DNS resolver / tunnel endpoint
- **dnslab-attacker** — launches the tunnel (iodine / dnstt)
- **dnslab-victim** — the host whose DNS is abused

Start all three, then from `dnslab-attacker` generate tunnel traffic (long,
high-volume DNS queries). This triggers custom rules **SID 1000020–1000022**
(oversized query name / TXT flood / query-volume anomaly) — the standout catch.

See [`../attacks/03-dns-tunnel.md`](../attacks/03-dns-tunnel.md) for the exact
commands and the interview explanation.

---

## Step 4 — Where the IDS runs (the "SOC" side)

You don't need the Raspberry Pi to start — run **Suricata inside a VM** that sees
the lab traffic:

**Option A (simplest): Suricata on the gateway VM.**
`dnslab-gateway` already sits between hosts, so traffic flows through it. Install
Suricata there and point it at the LAN interface:

```bash
sudo apt update && sudo apt install -y suricata
# copy the custom rules from this repo into /etc/suricata/rules/custom.rules
sudo suricata -i eth0 -c /etc/suricata/suricata.yaml
tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'
```

**Option B: Suricata on Kali**, monitoring its own interface, to watch what the
attacker generates (good for a quick first demo).

**Option C (final form): the Raspberry Pi**, per the main README — the Pi watches
your real home network. Move to this once the VM demo works.

Pull the detection rules/scripts straight from this repo inside any VM:

```bash
git clone https://github.com/muttakin210/securehome-soc
cd securehome-soc
sudo cp raspberry-pi/suricata/custom.rules /etc/suricata/rules/custom.rules
```

---

## Suggested order for your 1–2 weeks

1. Network fix (Step 0) + recon (Step 1) — **today**.
2. Suricata on the gateway/Kali (Step 4, Option A/B) + see the scan alert.
3. SSH brute force + block (Step 2).
4. DNS tunnel with the dnslab VMs (Step 3) — your signature catch.
5. Grafana dashboard (see [`../dashboards/`](../dashboards/)).
6. Record the demo ([`demo-playbook.md`](demo-playbook.md)) + push + post.

> ⚠️ Everything here runs only inside your own isolated VirtualBox lab against
> your own VMs. Never point these tools at systems you don't own.
