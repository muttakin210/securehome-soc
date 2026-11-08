# Attack 2 — SSH brute force

> ⚠️ Lab only. Target = your own Ubuntu server (10.10.20.100) with a throwaway
> account you created for this demo.

## Setup (on the target server, once)

```bash
sudo adduser labuser          # set a weak password ON PURPOSE for the demo
sudo systemctl enable --now ssh
```

Create a tiny wordlist on Kali:

```bash
printf '123456\npassword\nadmin\nlabuser\nStr0ng-Admin!\n' > wordlist.txt
```

## What the attacker does (Kali)

```bash
# Hydra: try each password against SSH
hydra -l labuser -P wordlist.txt ssh://10.10.20.100 -t 4

# (Alternative) medusa
# medusa -h 10.10.20.100 -u labuser -P wordlist.txt -M ssh
```

## What should happen (defence)

1. Each guess opens a **new TCP connection to port 22** (new SYN each time).
2. Suricata rule **SID 1000010** (`SECUREHOME SSH brute-force`) fires after 10 new
   connections from one source within 20s.
3. Grafana shows the alert and the attacker's `src_ip` in *Top attacking source IPs*.
4. **Response step (talk about this!):** add the attacker IP to the nftables
   `blocklist_v4` set, or wire **fail2ban** to do it automatically:
   ```bash
   sudo nft add element inet filter blocklist_v4 { 10.10.10.100 }
   ```
   Now the attacker is dropped at the firewall and the drop is logged too.

## Interview explanation

- **Layer 4/7:** SSH rides on TCP/22; the brute force is many short-lived TCP
  sessions, each attempting an SSH auth (L7).
- **Why threshold, not signature:** one failed login is normal. Ten in twenty
  seconds is an attack. We detect the **rate**, then **respond** by blocking the
  source — detection + response, the full SOC loop.
- **Real-world hardening you'd recommend:** key-based auth only, disable password
  login, fail2ban, move off default port, rate-limit at the firewall.
