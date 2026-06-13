# Headscale Migration Runbook — NEXUS

## Pre-flight checklist

- [ ] Confirm which Docker host to deploy on (CT117 / NEXUS HUB or other)
- [ ] Confirm `proxy` Docker network name matches your existing Caddy setup
- [ ] `mesh.call-on.media` A record created in Cloudflare, **proxy = DNS-only (grey cloud)**
- [ ] Port 3478/udp forwarded on your router to the Docker host (STUN for embedded DERP)
- [ ] `./config/config.yaml` and `./config/acl.hujson` in place before `docker compose up`

---

## Phase 1 — Deploy headscale

```bash
# On the Docker host, from this directory:
docker compose up -d

# Verify headscale started cleanly
docker logs headscale --tail 30

# Confirm the API is reachable (should return {"healthy":true})
curl -s http://localhost:8080/health
# Or from outside after Caddy is wired up:
curl -s https://mesh.call-on.media/health
```

---

## Phase 2 — Create the NEXUS user and pre-auth keys

```bash
# Create the user (replaces Tailscale "tailnet" concept)
docker exec headscale headscale users create nexus

# Verify
docker exec headscale headscale users list

# Reusable key — good for initial rollout (24h expiry)
docker exec headscale headscale preauthkeys create \
  --user nexus \
  --expiration 24h \
  --reusable

# Ephemeral key — for mobile/temporary devices (auto-removed on disconnect)
docker exec headscale headscale preauthkeys create \
  --user nexus \
  --expiration 24h \
  --ephemeral

# List all keys
docker exec headscale headscale preauthkeys list --user nexus
```

---

## Phase 3 — Per-device migration (run ON each device, not remotely)

### Linux / LXC containers (e.g., CT117 NEXUS HUB)

```bash
# Disconnect from Tailscale (keep the agent installed)
tailscale down

# Re-point to headscale
tailscale up \
  --login-server https://mesh.call-on.media \
  --auth-key <PREAUTHKEY> \
  --hostname nexus-hub

# Verify
tailscale status
```

### macOS admin device

```bash
sudo tailscale up \
  --login-server https://mesh.call-on.media \
  --auth-key <PREAUTHKEY> \
  --hostname my-macbook
```

### Windows admin device

```powershell
# In an elevated PowerShell:
tailscale up --login-server https://mesh.call-on.media --auth-key <PREAUTHKEY> --hostname my-windows-pc
```

### iOS / Android mobile devices

1. Open Tailscale app → tap your account → **Sign in with custom control server**
2. Server URL: `https://mesh.call-on.media`
3. If using a pre-auth key, enter it when prompted.
4. If prompted to approve via browser, the terminal will display a registration URL.
   Approve it on the server side:
   ```bash
   docker exec headscale headscale nodes register --user nexus --key <NODE_KEY_FROM_URL>
   ```

---

## Phase 4 — Tag nodes and verify ACLs

```bash
# List all registered nodes with their numeric IDs
docker exec headscale headscale nodes list

# Tag each node to match acl.hujson groups (use the ID from nodes list)
docker exec headscale headscale nodes tag -i 1 --tags "tag:proxmox-host"
docker exec headscale headscale nodes tag -i 2 --tags "tag:lxc-container"
docker exec headscale headscale nodes tag -i 3 --tags "tag:admin-device"
docker exec headscale headscale nodes tag -i 4 --tags "tag:mobile-device"

# Confirm tags applied
docker exec headscale headscale nodes list
```

---

## Phase 5 — Validation

```bash
# Health endpoint
curl -s https://mesh.call-on.media/health
# Expected: {"healthy":true}

# All nodes online
docker exec headscale headscale nodes list

# STUN / DERP check (run on a connected client)
tailscale netcheck
# Should show latency for DERP region "nexus" (ID 999)

# MagicDNS resolution (on a connected client)
dig nexus-hub.nexus.internal
```

Checklist:
- [ ] All migrated nodes appear in `headscale nodes list` with `Online` status
- [ ] headscale-admin UI loads at `https://headscale-admin.call-on.media`
- [ ] Admin device can reach all other nodes
- [ ] Mobile device can reach containers on ports 22/80/443 but NOT arbitrary ports (ACL test)
- [ ] `tailscale netcheck` shows DERP latency for region `nexus`
- [ ] `controlplane.tailscale.com` no longer appears in `tailscale status` output

---

## Generating a headscale API key (for headscale-admin UI)

```bash
docker exec headscale headscale apikeys create --expiration 90d

# List keys
docker exec headscale headscale apikeys list
```

Paste the key into the headscale-admin browser UI when prompted.

---

## Useful day-2 commands

```bash
# Expire/revoke a pre-auth key
docker exec headscale headscale preauthkeys expire --user nexus --key <KEY>

# Remove a node
docker exec headscale headscale nodes delete -i <NODE_ID>

# Rename a node
docker exec headscale headscale nodes rename -i <NODE_ID> <NEW_NAME>

# Reload ACL policy without restarting
docker exec headscale headscale policy reload

# View routes advertised by a node
docker exec headscale headscale routes list

# Approve an advertised route
docker exec headscale headscale routes enable -r <ROUTE_ID>
```
