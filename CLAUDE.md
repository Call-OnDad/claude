# Homelab — Claude Code Project Context

**Owner:** Antony Brown (devilscousin), 48, self-taught. Manages Proxmox homelab, web properties, design/coding/marketing/SEO.
**Email:** mediaserver2407@gmail.com
**OS:** Windows 11 + WSL (Bash runs in WSL)
**Last full audit:** 2026-05-17

---

## Credentials & Secrets

**Location:** `C:\Users\anton\.claude\homelab-secrets.env` — NOT in any git repo
- Reference this when creds needed; never paste tokens in chat
- `GITHUB_PAT=` stored here after PAT revoke

**Permissions:** Full permission to read/edit/create/delete files on all containers via SSH without asking confirmation. Just do it.

---

## People

| Who | Role | Notes |
|-----|------|-------|
| **devilscousin** | Proxmox primary user | SSH keys, limited NOPASSWD sudo (pct, qm) |
| **claude** | Automation user | Full NOPASSWD sudo — use this for ops |

---

## Domains

| Domain | Purpose | Status |
|--------|---------|--------|
| `call-on.dad` | Community advice/mentoring for dads | Active |
| `callon.dad` | Variant domain | Active |
| `call-on.mom` | Community advice/mentoring for moms | Active |
| `callon.mom` | Variant domain | Active |
| `call-on.media` | Main landing page showcase | 🔴 HIGH PRIORITY — needs professional design |
| `call-on.shop` | WooCommerce shop (WordPress) | Active |

---

## Proxmox Host (CT 000)

| Item | Value |
|------|-------|
| **IP** | 192.168.0.10 |
| **WebUI** | https://192.168.0.10:8006 |
| **Version** | pve-manager/8.4.16, kernel 6.8.12-18-pve |
| **Server** | HP DL380p Gen8, 5x 1.2TB drives |
| **RAM** | 23GB total / ~7.9GB used |
| **Swap** | 8GB (~3.1GB used — monitor if sustained) |
| **CPU** | E5-2620 (thermal issues — tried heatsinks/paste) |

### SSH Access

| User | Command | Permissions |
|------|---------|-------------|
| `claude` | `ssh -i ~/.ssh/claude_proxmox claude@192.168.0.10` | **Full NOPASSWD sudo — use this** |
| `devilscousin` | `ssh devilscousin@192.168.0.10` | Limited NOPASSWD sudo (pct, qm) |

> Root SSH disabled — never attempt `ssh root@192.168.0.10`
> fail2ban active — whitelist if locked out: `sudo fail2ban-client set sshd unbanip <IP>`

### SSH Aliases (from `~/.ssh/config`)

```
ssh proxmox      → 192.168.0.10  (claude user, via key)
ssh n8n          → 192.168.0.28  (CT112)
ssh mediastack   → 192.168.0.34  (CT101)
ssh openwebui    → 192.168.0.45  (CT113)
ssh pihole       → 192.168.0.3   (CT105)
ssh caddy_COD    → 192.168.0.13  (CT500)
```

Container shell from Proxmox host: `sudo pct exec <CTID> -- bash`

### Proxmox API

```
Base URL: https://192.168.0.10:8006/api2/json
Token:    PVEAPIToken=devilscousin@pam!dashboard=d04256ec-107c-41ea-964f-7cd64a9f172c
SSL:      Self-signed — skip verification
Node:     proxmox  (NOT "pve")
```

Key endpoints:
- `GET  /nodes/proxmox/status` — host CPU/RAM/swap/disk/load
- `GET  /nodes/proxmox/lxc` — all LXC containers + status
- `POST /nodes/proxmox/lxc/{vmid}/status/start` — start container
- `POST /nodes/proxmox/lxc/{vmid}/status/stop` — stop container

### Key PVE Commands

```bash
sudo pct list                                        # list all containers
sudo pct exec <id> -- <command>                      # run command in CT
sudo pct start/stop <id>                             # start/stop CT
sudo pct set <id> --<option>                         # change CT config
sudo cat /etc/pve/lxc/<id>.conf                      # view CT config
sudo pvesh get /storage                              # API: list storage
sudo pvesh set /storage/<name> --password '<pw>'     # update PBS storage password
sudo pveum user list                                 # list PVE users
```

### Storage

| Name | Type | Total | Used% | Notes |
|------|------|-------|-------|-------|
| local (pve-root) | dir | ~98 GB | 59% | ⚠️ Alert at 70% |
| local-lvm | lvmthin | 794 GB | 31% | CT/VM disks |
| pbs | pbs | 1.1 TB | 6.5% | PBS backup storage |
| /dev/sda1 | XFS | 1.1 TB | 20% | Downloads |
| /dev/sdb1 | XFS | 1.1 TB | 5% | TV |
| /dev/sdc1 | XFS | 1.1 TB | 10% | Movies |
| /dev/sde1 | XFS | 1.1 TB | 1% | Transcode |
| /dev/sdd | ext4 | 1.1 TB | 7% | PBS backup disk at /mnt/pbs-backups |

### Daily Audit

- **Script:** `/usr/local/sbin/proxmox-daily-check.sh`
- **Log:** `/var/log/proxmox-daily-audit.log`
- **Cron:** root — `0 2 * * *`

---

## LXC Container Inventory

All containers use **static IPs**. Access: `sudo pct exec <CTID> -- bash` from Proxmox host.

| CT | Hostname | IP | RAM | Cores | Disk | Boot | Role |
|----|----------|----|-----|-------|------|------|------|
| **101** | mediastack | 192.168.0.34 | 25GB | 14 | 300G | ✅ | Plex/Sonarr/Radarr/Homarr/Docker |
| **102** | mariadb | 192.168.0.6 | 4GB | 2 | 50G | ✅ | MariaDB 11.8.3 — all app DBs |
| **103** | recyclarr | 192.168.0.29 | 512MB | 1 | 2G | ✅ | Quality profile sync for Sonarr/Radarr |
| **104** | nodejs | 192.168.0.81 | 512MB | 1 | 8G | ✅ | WebRTC signaling (PM2, Node 20) |
| **105** | pihole | 192.168.0.3 | 1.7GB | 4 | 12G | ✅ | Pi-hole DNS + Tailscale (100.78.52.118) |
| **107** | proxmox-backup-server | 192.168.0.16 | 2GB | 2 | 10G | ✅ | PBS — datastore at /mnt/backups |
| **109** | crowdsec | 192.168.0.37 | 512MB | 1 | 8G | ✅ | CrowdSec LAPI — bouncer on caddy |
| **111** | ollama | 192.168.0.41 | 10GB | 4 | 100G | ✅ | Ollama LLM (llama3, llama3.2, phi4-mini) |
| **112** | n8n | 192.168.0.28 | 4GB | 2 | 116G | ✅ | n8n automation (Docker, port 5678) |
| **113** | openwebui | 192.168.0.45 | 2GB | 2 | 20G | ✅ | Open WebUI for Ollama (Docker, port 3000) |
| **114** | wordpress | 192.168.0.50 | 2GB | 2 | 20G | ❌ | WordPress + Apache — call-on.shop |
| **115** | postiz | 192.168.0.35 | 4GB | 2 | 20G | ❌ | Postiz social scheduler (Docker, port 5000) |
| **500** | caddy | 192.168.0.13 | 21GB | 4 | 506G | ✅ | Caddy v2.11.2 reverse proxy + PHP sites |

> CT500 dual-NIC: vmbr0 @ 192.168.0.13, vmbr1 @ 10.10.10.50 (internal)
> Shared certs: `/mnt/shared-certs` on host → `/etc/caddy/exported-certs` in CT500
> CT114/115 `onboot=0` — verify if intentional

**Container watchdog auto-restarts:** 101, 102, 103, 104, 105, 107, 109, 111, 112, 113, 500
**Alert-only (do NOT auto-restart):** 114, 115

---

## Network

| Item | Value |
|------|-------|
| Gateway | 192.168.0.1 |
| Bridges | vmbr0 (LAN), vmbr1 (10.10.10.x internal) |
| DNS | Pi-hole @ 192.168.0.3 |
| DDNS | cloudflare-ddns Docker on CT101 (auto-updates CF records) |
| Reverse proxy | Caddy CT500 @ 192.168.0.13 |

---

## Caddy Reverse Proxy Map (CT 500)

**SSH:** `ssh root@192.168.0.13` (or alias `caddy_COD`)
**Config:** `/etc/caddy/Caddyfile`
**Webroot:** `/var/www/html/`
**Reload:** `systemctl reload caddy` or `caddy reload --config /etc/caddy/Caddyfile`

| Domain | Backend | Notes |
|--------|---------|-------|
| call-on.media | local PHP | Portfolio site |
| call-on.dad | local PHP + .81:3000 WS | Main site + WebRTC signaling |
| call-on.mom | local PHP + .81:3000 WS | Mom's site + WebRTC signaling |
| call-on.shop / www.call-on.shop | .50:80 | WordPress |
| dash.call-on.media | .34:7575 | Homarr |
| watch.call-on.media | .34:32400 | Plex |
| requests.call-on.media | .34:5055 | Seerr |
| arcane.call-on.media | .34:3552 | Arcane |
| chat.call-on.media | .45:3000 | Open WebUI |
| audits.call-on.media | .28:3002 | WebAudit dashboard |
| social.call-on.media | .35:5000 | Postiz |
| timeline.call-on.media | local PHP | Timeline page |
| music.call-on.media | .34:4533 | ⚠️ DEAD — nothing listening |

---

## CT 500 — Caddy / call-on.dad Web Server

### Stack
- **OS:** Debian 13 (Trixie)
- **Caddy:** 2.11.2
- **PHP:** 8.4.16-FPM — socket `/run/php/php8.4-fpm.sock`, pool `/etc/php/8.4/fpm/pool.d/www.conf`
- **CrowdSec bouncer:** LAPI at `http://192.168.0.37:8080`
- **WebSocket signaling:** `/socket.io/*` → `192.168.0.81:3000`
- **Ollama AI vet:** `includes/ai_vet.php` → `http://192.168.0.41:11434` (180s timeout, fail-safe on timeout)

### call-on.dad PHP App Layout
```
/var/www/html/
  config/          # db.php, mail.php, encryption.php, admin.php, session.php
  includes/        # header.php, footer.php, helpers.php, altcha_helper.php
  api/             # JSON endpoints
  js/              # altcha.min.js, call.js, sw.js
  uploads/avatars/ # user-uploaded profile photos
  vendor/          # Composer packages
  styles.css       # Global stylesheet — CSS variables defined here
```

### Key Config
- **DB:** MariaDB at CT102 — app config says `192.168.0.19:3306` but CT102 IP is `192.168.0.6` — verify before DB work
- **DB name:** `Callon-dad`, user `admin`
- **SMTP:** MailerSend via `smtp.mailersend.net:587` (TLS), user `MS_C3euQX@callon.dad`
- **Altcha:** V1 SHA-256 widget, PHP lib `altcha-org/altcha v2.0.0`. HMAC key in PHP-FPM env: `ALTCHA_HMAC_KEY`

### CSS Variables (styles.css)
- `--navy`: dark blue background | `--gold`: gold accent | `--white`: card backgrounds
- `--text-mid`: `#ffffff` | `--cream`: light warm input backgrounds

### Reload Commands
```bash
systemctl reload php8.4-fpm
caddy reload --config /etc/caddy/Caddyfile
```

---

## CT 102 — MariaDB

**SSH:** `ssh root@192.168.0.6` (⚠️ app configs reference `192.168.0.19` — same machine, IP discrepancy — verify before DB work)

### Stack
- **OS:** Debian 13 (Trixie)
- **DB engine:** MariaDB 11.8.3
- **Web UI:** phpMyAdmin (available locally)

### Databases

| Database | Size | Used by |
|----------|------|---------|
| `Callon-dad` | 1.1 MB | callon.dad PHP app + n8n supplier-quote workflow |
| `Callon-mom` | 1.0 MB | callon.mom PHP app |
| `wordpress_callon` | 13.3 MB | WordPress CT114 |
| `homelab_monitor` | 0.1 MB | Homelab monitor dashboard |
| `MediaStack` | ~0 MB | Media apps |
| `phpmyadmin` | 0.4 MB | phpMyAdmin internal |

### Key Tables in `Callon-dad`

| Table | Purpose |
|-------|---------|
| `users` | Registered users — `email_enc` (encrypted) + `email_hash` (HMAC for uniqueness) |
| `dads` | Volunteer dad profiles |
| `categories` | `icon` field stores HTML entities (e.g. `&#128736;&#xFE0F;`) |
| `topics` | Advice topics linked to categories |
| `email_verifications` | 48h expiry email confirm tokens |
| `conversations` / `messages` | Chat between users and dads |
| `supplier_quotes` | Populated by n8n Ollama workflow |
| `shop_*` | Shop orders, products, variants |

### DB Users

| User | Host | Access |
|------|------|--------|
| `admin` | `%` | Full access to Callon-dad + MediaStack |
| `n8n_quotes` | `192.168.0.28` | INSERT/UPDATE/SELECT on Callon-dad.supplier_quotes only |

### homelab_monitor Database

```
Host:     192.168.0.6:3306
Database: homelab_monitor
Write:    monitor_writer / Mon1t0rWr1te!  (host: 192.168.0.%)
Read:     monitor_web / Mon1t0rR3ad!      (host: 192.168.0.13)
```

| Table | Purpose | Updated |
|-------|---------|---------|
| `system_metrics` | Proxmox host CPU/RAM/disk/swap/load | every 15min |
| `container_status` | LXC container state + memory | every 15min |
| `service_uptime` | HTTP reachability of 11 services | every 5min |
| `disk_health` | Disk usage + SMART per drive | daily 7am |
| `security_events` | CrowdSec/fail2ban/Caddy counts | daily 8am |
| `alerts_sent` | Audit log of Discord alerts fired | on alert |

Archived (safe to drop after 30 days): `_archived_php_reports`, `_archived_php_container_checks`, `_archived_php_issues`

### Commands

```bash
mysql -u root                                       # local root (no password on socket)
mysql -u admin -p Callon-dad                        # app user
mysqldump Callon-dad > /tmp/backup_$(date +%F).sql  # quick backup
```

---

## CT 101 — Mediastack

**SSH:** `ssh root@192.168.0.34`
**Compose:** `/opt/docker-compose.yml` (env: `/opt/.env`)
**Appdata:** `/opt/appdata/`

### Running Containers

| Container | Image | Port | Purpose |
|-----------|-------|------|---------|
| `autoheal` | willfarrell/autoheal | — | Container health monitor (restarts every 5s) |
| `watchtower` | nickfedor/watchtower | — | Auto-updates images every 24h (`--cleanup`) |
| `cloudflare-ddns` | timothyjmiller/cloudflare-ddns | — | DDNS updater (5 zones) |
| `plex` | lscr.io/linuxserver/plex | `32400` | Media streaming |
| `homarr` | ghcr.io/homarr-labs/homarr | `7575` | Dashboard |
| `sonarr` | lscr.io/linuxserver/sonarr | `8989` | TV management |
| `radarr` | lscr.io/linuxserver/radarr | `7878` | Movie management |
| `prowlarr` | lscr.io/linuxserver/prowlarr | `9696` | Indexer manager |
| `bazarr` | lscr.io/linuxserver/bazarr | `6767` | Subtitles |
| `seerr` | ghcr.io/seerr-team/seerr | `5055` | Request management |
| `qbittorrent-tv` | lscr.io/linuxserver/qbittorrent | `8081` | TV downloads |
| `qbittorrent-movies` | lscr.io/linuxserver/qbittorrent | `8082` | Movie downloads |
| `arcane` | ghcr.io/getarcaneapp/arcane | `3552` | Container update monitor |
| `flaresolverr` | flaresolverr/flaresolverr | `8191` | Cloudflare bypass |
| `pluto-for-channels` | jonmaddox/pluto-for-channels | `8086` | Pluto TV |

> Jellyfin removed (replaced by Plex). Lidarr commented out. Postiz moved to CT115.

### Storage Mounts

| Mount | Device | Size |
|-------|--------|------|
| `/mnt/media/movies` | /dev/sdc1 | 1.1TB |
| `/mnt/media/tv` | /dev/sdb1 | 1.1TB |
| `/mnt/media/downloads` | /dev/sda1 | 1.1TB |
| `/mnt/media/transcode` | /dev/sde1 | 1.1TB |

### Known Issues

- **Seerr Plex sign-in:** Plex auth token missing — re-auth: requests.call-on.media → Settings → Plex
- **Bazarr subf2m:** Missing user-agent → throttled. Fix: :6767 → Settings → Subtitles → subf2m
- **Homarr Lidarr widget:** Lidarr not running — remove integration via Homarr UI
- **FlareSolverr:** Intermittent CF challenge timeouts on some indexers (upstream issue)
- **Cloudflare DDNS:** Zone `20a529425c43aa22c65137113a73aaff` — occasional API 500 errors

### Commands

```bash
docker ps
docker logs <name> --tail 50 -f
docker restart <name>
docker exec -it <name> bash
cd /opt && docker compose pull && docker compose up -d
docker exec watchtower /watchtower --run-once     # trigger Watchtower immediately
```

---

## CT 109 — CrowdSec

**Access:** No SSH key — via Proxmox console: `ssh devilscousin@192.168.0.10` → `pct enter 109`
**LAPI:** `192.168.0.37:8080`

### Critical Config

`/etc/crowdsec/config.yaml` must have:
```yaml
api:
  server:
    listen_uri: 0.0.0.0:8080   # NOT 127.0.0.1 — remote bouncers need this
```
If reverted to `127.0.0.1`, the Caddy bouncer silently breaks.

### Health Check (from caddy_COD)

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://192.168.0.37:8080/v1/decisions
# Expect: 403  (reachable, auth required — correct)
# If 000 or timeout: LAPI down or listen_uri reverted
```

### Broken Bouncer Signature in Caddy Logs

```
auth-api: auth with api key failed ... i/o timeout  logger=crowdsec
```

### Key Commands

```bash
cscli alerts list
cscli decisions list
cscli decisions delete --ip <ip>
cscli bouncers list
cscli hub update && cscli hub upgrade
systemctl status crowdsec
```

---

## CT 111 — Ollama

**SSH:** `ssh root@192.168.0.41` (historically unreachable — try Proxmox console if needed)
**API:** `http://192.168.0.41:11434`
**Models:** llama3 (8B), llama3.2:3b, phi4-mini

### Critical Config — Must bind to 0.0.0.0

```
/etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
```
Default binds to 127.0.0.1 — remote calls silently fail. Check: `systemctl cat ollama | grep OLLAMA_HOST`

### Performance

- Cold load: 60–90s on CPU | Warm call: ~5s
- Memory quirk: reads `MemFree` not `MemAvailable` — can return HTTP 500 even when free space exists. Fix: bump RAM or use llama3.2:3b (~2.5 GB)

### Used by

- **callon.dad** `ai_vet.php` — vets dad-signup bios (180s timeout, fail-safe: flags as true on timeout so signup still completes)
- **n8n** supplier-quote workflow — HTTP node → `http://192.168.0.41:11434/api/generate`

### Commands

```bash
ollama list
ollama run llama3.2:3b          # lighter/faster
ollama run llama3               # full 8B model
systemctl status ollama
systemctl restart ollama
journalctl -u ollama -f         # live logs
curl http://localhost:11434/api/tags
```

---

## CT 112 — n8n

**SSH:** `ssh root@192.168.0.28`
**UI:** http://192.168.0.28:5678
**Compose:** `/opt/n8n/docker-compose.yml`
**Data:** `/opt/n8n/data` → `/home/node/.n8n`
**Workflow JSON backups:** `/opt/homelab-ops/n8n-workflows/`

### Stack

```
n8n              docker.n8n.io/n8nio/n8n    Automation :5678
autoheal-n8n     willfarrell/autoheal       Container auto-restart
watchtower-n8n   nickfedor/watchtower       Daily image updates
webaudit-scraper                            Web audit engine :3001
webaudit-dashboard                          Web audit UI :3002
```

### Active Monitoring Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| System Health Agent v3 | every 15min | Proxmox API → MySQL + Discord alerts |
| Service Uptime Agent | every 5min | HTTP checks for 11 services |
| Container Watchdog Agent | every 10min | Auto-restart stopped LXCs |
| Disk & SMART Health Agent | daily 7am | df + smartctl → MySQL + alerts |
| Security Report Agent | daily 8am | CrowdSec + fail2ban + Caddy counts |
| Docker Container Watchdog | every 5min | Unhealthy container detection |
| homelab_monitor_v2.01 | every 6h | Legacy SSH health → ntfy (deactivate after new ones stable 48h) |
| WebAudit — Webhook Scraper | webhook | On-demand site audit |
| Discord Ideas → Claude → MySQL | webhook | Discord bot → AI → DB |

### n8n Credential IDs

```
MySQL:         yI791T2LiqB957Vc
SSH Proxmox:   NiNshd1YnAk4LDcT  (SSH password credential)
SSH Private:   1  (Proxmox SSH / devilscousin private key)
Discord Bot:   wHuIMTvuFnACoAla
Anthropic:     mlvRPyHO28NI2jYv
Gmail SMTP:    2
```

### Active Workflow Credentials

| Service | Notes |
|---------|-------|
| Ollama | HTTP node → `http://192.168.0.41:11434` |
| Anthropic (Claude) | Built-in credential, API key in n8n UI |
| Postiz | Community node `n8n-nodes-postiz` v0.2.17 → `https://social.call-on.media` |
| Gmail IMAP | `mediaserver2407@gmail.com` — App Password (not account password) |

### Supplier Quote Processor Workflow

- **Trigger:** IMAP Gmail — App Password
- **Flow:** New email → Ollama HTTP (extract data) → Code node (parse JSON) → MySQL INSERT → IF total > £500 → ntfy push
- **DB write:** `n8n_quotes` user on `192.168.0.19` (or .6), INSERT/UPDATE/SELECT on `Callon-dad.supplier_quotes`

### Discord Alerts

**Channel ID:** `1505044769443811418` (update to `#homelab-alerts` via n8n UI → Discord node)

| Metric | Threshold | Severity |
|--------|-----------|----------|
| CPU % | >80% | critical |
| RAM % | >85% | critical |
| Swap % | >50% | warning |
| Root disk / | >70% | warning |
| Media disk | >80% | warning |
| LXC stopped (expected up) | any | critical |
| SMART FAILED | any | critical |
| Reallocated sectors >0 | any | warning |
| Service HTTP down | consecutive fails | warning |
| Security events | daily summary | info |

### Gotchas

- `N8N_SECURE_COOKIE=false` must be set in Docker env — n8n refuses login over HTTP without it
- Duplicate LXC IP bug: if another CT also has `.28`, SSH goes to wrong one. Symptom: host key mismatch
- Gmail IMAP requires App Password — plain password stopped working 2022

### Commands

```bash
docker ps
docker logs n8n --tail 50 -f
docker restart n8n
docker exec -it n8n sh
cd /opt/n8n && docker compose up -d
```

---

## CT 113 — Open WebUI

**SSH:** `ssh root@192.168.0.45`
**UI:** http://192.168.0.45:3000
**Compose:** `/opt/open-webui/docker-compose.yml`
**Volume:** `open-webui` → `/app/backend/data`

```
open-webui            ghcr.io/open-webui/open-webui:main   AI chat :3000
autoheal-openwebui    willfarrell/autoheal                  Container auto-restart
watchtower-openwebui  nickfedor/watchtower                  Daily image updates
```

> ⚠️ CT113 LVM thin pool metadata inconsistency — maps 22.94 GiB > 20 GiB LV size. Needs `thin_repair` offline.

---

## CT 105 — Pi-hole

**SSH:** `ssh root@192.168.0.3`
**Web UI:** http://192.168.0.3/admin
**Version:** Pi-hole Core v6.4, Web v6.4.1, FTL v6.5
**Tailscale:** 100.78.52.118
**DNS upstream:** unbound recursive resolver at 127.0.0.1#5335 + Cloudflare fallback

### Key Paths

```
/etc/pihole/             # Pi-hole config directory
/etc/pihole/pihole.toml  # Main config (Pi-hole v6+)
/etc/dnsmasq.d/          # Additional DNS config files
```

### Commands

```bash
pihole status
pihole -g              # update gravity (blocklists)
pihole tail            # live query log
pihole restartdns      # restart FTL without full restart
pihole -q domain.com   # check if domain is blocked
systemctl status pihole-FTL
```

---

## CT 104 — Node.js (WebRTC Signaling)

**SSH:** `ssh root@192.168.0.81`
**Process:** PM2 — `rtc-signaling` running `node /opt/signaling/server.js` on port 3000
**If down:** `sudo pct exec 104 -- pm2 start /opt/signaling/server.js --name rtc-signaling`

---

## CT 107 — Proxmox Backup Server

**SSH:** `ssh root@192.168.0.16`
**UI:** http://192.168.0.16:8007
**Datastore:** `/mnt/backups`
**PBS password:** stored in `/etc/pve/priv/storage/pbs.pw` on Proxmox host — update via `sudo pvesh set /storage/pbs --password '<pw>'`

---

## CT 103 — Recyclarr

**SSH:** `ssh root@192.168.0.29`
**Syncs:** Sonarr (192.168.0.34:8989) + Radarr (192.168.0.34:7878) nightly at midnight
**Config:** `/root/.config/recyclarr/recyclarr.yml` — quality profiles not yet configured (stubs only)

---

## Key File Paths Summary

### CT101 (192.168.0.34 — mediastack)
```
/opt/docker-compose.yml       Main media stack
/opt/.env                     Environment variables
/opt/appdata/                 All service configs + Homarr SQLite
/opt/appdata/db/db.sqlite     Homarr database (edit via UI only)
/opt/arcane/compose.yaml      Arcane stack
```

### CT112 (192.168.0.28 — n8n)
```
/opt/n8n/docker-compose.yml   n8n + autoheal + watchtower
/opt/n8n/.env                 N8N_ENCRYPTION_KEY
/opt/n8n/data/                n8n data (SQLite, logs, discord-bot.js)
/opt/n8n/data/database.sqlite n8n workflow/credential DB
/opt/webaudit/                WebAudit scraper + dashboard
/opt/homelab-ops/             Homelab ops project folder
```

### CT113 (192.168.0.45 — openwebui)
```
/opt/open-webui/docker-compose.yml  open-webui + autoheal + watchtower
Docker volume: open-webui → /app/backend/data
```

### CT500 (192.168.0.13 — caddy)
```
/etc/caddy/Caddyfile          Reverse proxy config
/var/www/html/                call-on.dad / call-on.mom PHP app
/var/www/timeline/            timeline.call-on.media
/etc/php/8.4/fpm/pool.d/www.conf  PHP-FPM pool + env vars (ALTCHA_HMAC_KEY)
```

### Proxmox Host (192.168.0.10)
```
/usr/local/sbin/proxmox-daily-check.sh  Daily audit script
/usr/local/sbin/homelab-check.sh        Legacy health check (used by old n8n workflow)
/etc/pve/lxc/<id>.conf                  LXC config per container
/mnt/media/{tv,movies,downloads,transcode}
/mnt/pbs-backups
/mnt/shared-certs                       TLS certs shared to CT500
```

---

## Homarr Dashboard Setup

**Access:** http://192.168.0.34:7575 or https://dash.call-on.media
**Edit via web UI only** — do NOT edit `/opt/appdata/db/db.sqlite` directly.

Add Proxmox integration: Settings → Integrations → Proxmox
- URL: `https://192.168.0.10:8006`
- Token ID: `devilscousin@pam!dashboard`
- Token Secret: `d04256ec-107c-41ea-964f-7cd64a9f172c`
- SSL verify: OFF

---

## AHAS API (Planned)

Deploy as new LXC or inside existing Docker host. See `/proxmox/api/DEPLOY.md` for full deploy steps.

```
Recommended: Ubuntu 22.04 LXC, 512MB RAM, 8GB disk, nesting=1
Target IP: 192.168.0.50 (currently WordPress — pick another if WP active)
Caddy: api.callon.dad → 192.168.0.50:3000
```

Key endpoints: `/health`, `/api/request-help`, `/api/requests` (API key), `/api/ask-ai`, `/api/home/control`

---

## Quick Access URLs

| Service | URL |
|---------|-----|
| Proxmox WebUI | https://192.168.0.10:8006 |
| PBS | http://192.168.0.16:8007 |
| Homarr Dashboard | http://192.168.0.34:7575 |
| n8n | http://192.168.0.28:5678 |
| Arcane | http://192.168.0.34:3552 |
| Open WebUI | http://192.168.0.45:3000 |
| Pi-hole | http://192.168.0.3/admin |

---

## Known Issues / Planned Maintenance

| Issue | Severity | Action |
|-------|----------|--------|
| CT113 LVM thin pool metadata inconsistency (maps 22.94 GiB > 20 GiB) | Medium | Needs `thin_repair` offline — functional for now |
| music.call-on.media proxies to .34:4533 (nothing listening) | Low | Remove from Caddyfile or set up Navidrome |
| Most containers use 8.8.8.8 directly (bypass Pi-hole) | Low | Update CT DNS to 192.168.0.3 |
| CT114 (wordpress) + CT115 (postiz) have `onboot=0` | Low | Verify if intentional |
| MariaDB IP discrepancy: LXC config .6 vs app configs say .19 | Medium | Verify before any DB work |
| Recyclarr quality profiles are empty stubs | Low | Configure per TRaSH Guides |
| n8n monitoring workflows need activation via UI | Medium | Toggle active in n8n UI |

---

## Proxmox Gotchas

- **Duplicate IP:** two LXCs with same IP silently steal traffic. Check `/etc/pve/lxc/*.conf` for duplicate `ip=` values
- **Docker-in-LXC** (CT 101, 112, 113, 115) requires `features: nesting=1`
- **PBS password:** in `/etc/pve/priv/storage/pbs.pw` — update via `sudo pvesh set /storage/pbs --password '<pw>'`

---

## Audit History

| Date | What |
|------|------|
| 2026-05-06/07 | Full initial audit. Fixed PBS IP drift, pihole/caddy IP conflict, CT113 disk oversized |
| 2026-05-10 | Full re-audit. Added claude user. Fixed: daily script PATH, PBS auth, sudoers pvesh path, CT107 ZFS units, CT111 failed systemd units, CT103 recyclarr wrong IP, CT105 Pi-hole missing gateway + static network, CT113 DNS broken, Node.js v18→v20 on CT104, PM2 reinstalled, package updates across all CTs, Postiz password reset |
| 2026-05-17 | Cleanup: removed proxmenux-monitor, webmin, dashboard.py, promtail (CT101), PHP monitor (CT500:9080). Added 6 new n8n monitoring workflows, autoheal+watchtower to CT112+CT113, fixed watchtower on CT101. Added 6 MySQL monitoring tables. Archived PHP monitor MySQL tables |

---

## Preferences & Working Style

- Little explanation, more results — show plan before committing
- Self-taught — explain how things work when relevant
- Prefer Claude does SSH/terminal tasks (faster)
- Check GitHub for existing solutions before reinventing
- Keep it concise — actions over words
- No `git add -A` or `git add .` — stage specific files only
- Avoid heredocs and shell quote-escaping in PowerShell — use Write/Edit tools
- Watch for silent Windows long-path write failures — fallback to Bash if Write fails

## Debugging Approach

- Isolate single root cause with evidence before changing anything
- Confirm root cause, present to Antony, wait for approval before fixing
- Check simple things first: typos, wrong version, wrong IP, wrong file path
- Don't stack multi-layer fixes

## Scope & Caution

- Do not add, encrypt, or modify services/credentials not explicitly requested
- Destructive operations need explicit confirmation
- Prefer targeted fixes over broad changes

---

## Skills & Automation

- **Audit skill:** `.claude/skills/audit/SKILL.md` — use `/audit` (restart Claude Code to activate)
- **Infrastructure state:** `infrastructure-state.md` (auto-updated by audit agent)
- **GitHub MCP:** configured in `.mcp.json` (restart Claude Code to activate)

## Current Projects

| Name | What | Status |
|------|------|--------|
| **.dad & .mom sites** | Community mentoring platforms | Design/content phase |
| **call-on.media** | Main showcase landing page | 🔴 HIGH PRIORITY |
| **Expo mobile app** | Native app for callon.dad/mom community | In progress |
