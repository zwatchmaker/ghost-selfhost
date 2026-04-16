# ghost-selfhost

Self-hosted Ghost blog deployments on Hetzner VPS via Ansible.

One command to deploy a production-ready Ghost instance with Docker, nginx, SSL, and auto-updates.

---

## What it does

- Provisions a fresh Ubuntu 24.04 VPS from scratch
- Installs Docker, nginx, certbot, fail2ban, UFW
- Deploys Ghost + MySQL via Docker Compose
- Configures nginx as a reverse proxy
- Obtains a Let's Encrypt SSL certificate
- Sets up **Watchtower** for automatic Ghost updates (every Monday 4am)
- Sets up **SSL auto-renewal** via cron
- Fully parameterized -- deploy as many sites as you want from one repo

---

## Requirements

**On your local machine:**
- Python 3 (`python3 --version` to check -- comes pre-installed on macOS 12+)
- Ansible including `ansible-vault`:
  ```bash
  # macOS
  brew install ansible

  # Ubuntu/Debian
  sudo apt install ansible-core

  # Any platform via pip
  pip3 install ansible
  ```
- Git (`brew install git` or comes pre-installed on macOS)
- An SSH key pair -- if you don't have one, generate it:
  ```bash
  ssh-keygen -t ed25519 -C "your@email.com"
  # Creates ~/.ssh/id_ed25519 (private) and ~/.ssh/id_ed25519.pub (public)
  ```

**On the target server:**
- Fresh Hetzner VPS (Ubuntu 24.04 recommended)
- Your SSH public key added to the VPS -- Hetzner lets you add it at creation time, or manually:
  ```bash
  ssh-copy-id root@YOUR_VPS_IP
  ```
- SSH access with root for first deploy only (playbook creates a dedicated `ghost` user)
- A domain with an A record pointing to the VPS IP

**Verify everything is ready before deploying:**
```bash
ansible --version          # should show 2.x or higher
python3 --version          # should show 3.8 or higher
ssh root@YOUR_VPS_IP       # should connect without a password prompt
dig yourdomain.com +short  # should return your VPS IP
```

---

## Quick Start

### 1. Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zwatchmaker/ghost-selfhost/main/install.sh)
cd ~/ghost-selfhost
```

Or clone manually:

```bash
git clone https://github.com/zwatchmaker/ghost-selfhost.git
cd ghost-selfhost
```

### 2. Create your vars file

```bash
cp vars/example.yml vars/mysite.yml
nano vars/mysite.yml
```

Fill in your domain, SMTP credentials, and database passwords.
See `vars/example.yml` for full documentation of every field.

### 3. Add your VPS to inventory

```bash
nano inventory.yml
```

Add your VPS:

```yaml
ghost_servers:
  hosts:
    mysite:
      ansible_host: YOUR_VPS_IP
      ansible_user: root                                 # root for first deploy only
      ansible_ssh_private_key_file: ~/.ssh/id_ed25519
      client_name: mysite
```

> **Note:** `root` is only needed for the initial deploy. The playbook creates a dedicated
> `ghost` system user and adds it to the docker group. After the first deploy you can
> change `ansible_user` to `ghost` for all subsequent runs.

### 4. Set up DNS

Add an A record at your DNS provider pointing your domain to your VPS IP.

Verify propagation before deploying:

```bash
dig yourdomain.com +short
# Should return your VPS IP
```

> **Cloudflare users:** Turn off the proxy (orange cloud → grey cloud) for the A record.
> Certbot needs a direct connection to issue the SSL certificate.

### 5. Encrypt your secrets

```bash
ansible-vault encrypt vars/mysite.yml
```

You'll set a vault password. Keep it safe -- you'll need it every time you run a playbook.

### 6. Deploy

```bash
ansible-playbook deploy.yml -i inventory.yml \
  --extra-vars "client_name=mysite" \
  --ask-vault-pass
```

Done. Ghost will be live at `https://yourdomain.com` in ~5 minutes.

---

## Interactive Setup

Instead of editing files manually, use the interactive script:

```bash
bash scripts/new-site.sh
```

It prompts for all required values, creates the vars file, encrypts it, and updates inventory automatically.

---

## Updating Ghost

Ghost updates automatically every Monday at 4am via Watchtower. You'll receive an email when an update is applied.

To update manually:

```bash
bash scripts/update.sh mysite
```

---

## Multiple Sites

Each site gets its own vars file and inventory entry. Use a different `ghost_port` for each site if hosting multiple sites on the same VPS.

```bash
# Site 1
cp vars/example.yml vars/site1.yml   # set ghost_port: 2368
cp vars/example.yml vars/site2.yml   # set ghost_port: 2369
```

Deploy each independently:

```bash
ansible-playbook deploy.yml -i inventory.yml --extra-vars "client_name=site1" --ask-vault-pass
ansible-playbook deploy.yml -i inventory.yml --extra-vars "client_name=site2" --ask-vault-pass
```

---

## After Deployment

1. Visit `https://yourdomain.com/ghost` to create your admin account
2. Set your site title and description in Ghost Admin → Settings
3. Upload a theme in Ghost Admin → Settings → Design
4. Configure Mailgun for newsletter delivery: Settings → Newsletters → Mailgun
5. Delete the default Ghost content (test posts, coming soon page)

---

## DNS Reference

| Provider | How to add an A record |
|----------|----------------------|
| GoDaddy | DNS Management → Add Record → Type: A → Name: @ → Value: VPS IP |
| Namecheap | Advanced DNS → Add New Record → A Record → Host: @ → Value: VPS IP |
| Cloudflare | DNS → Add record → Type: A → **proxy OFF (grey cloud)** → Value: VPS IP |
| Route53 | Hosted Zones → domain → Create record → Type: A → Value: VPS IP |
| Squarespace | Domains → DNS Settings → Custom Records → Type: A → Value: VPS IP |

---

## Security

- UFW firewall -- only ports 22, 80, 443 are open
- fail2ban -- blocks SSH brute force attempts
- Dedicated `ghost` system user -- Ghost containers never run as root
- Nginx security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- No secrets in inventory -- all credentials in ansible-vault encrypted vars files
- `.gitignore` prevents accidental commit of unencrypted vars

---

## File Structure

```
ghost-selfhost/
├── install.sh          # One-line bootstrap
├── deploy.yml          # Main deployment playbook
├── update.yml          # Update Ghost to latest
├── inventory.yml       # VPS hosts (no secrets, safe to commit)
├── .gitignore
├── scripts/
│   ├── new-site.sh     # Interactive site setup
│   └── update.sh       # Manual update helper
└── vars/
    └── example.yml     # Template with full documentation (safe to commit)
                        # Your site vars go here -- gitignored when encrypted
```

---

## Contributing

PRs welcome. This repo is intentionally minimal -- one playbook per concern.

If you add support for other apps (Wordpress, Plausible, n8n, etc.) keep them as separate playbooks in the root.

---

## License

MIT
