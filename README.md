# 🛡️ Docker Backup Bot

A lightweight containerized backup solution for Docker environments with support for:

- 🔐 GPG encryption
- 📤 Telegram & Email notifications
- ♻️ Backup rotation (keep latest N backups)
- 🕐 Cron-based automation
- 📦 Multi-platform image build via GitHub Actions
- 📄 Full timestamped logs with severity levels

---

## 📁 Project Structure

```

.
├── backup.sh                # Main backup script
├── crontab                 # Cron job definition
├── docker-compose.yml      # Docker service definition
├── Dockerfile              # Image definition
├── entrypoint.sh           # Startup script
├── .env.example            # Example environment config
├── msmtprc.template        # Email config template
├── .github/workflows/      # GitHub Actions CI
└── README.md               # This file

````

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/docker-backup-bot.git
cd docker-backup-bot
````

### 2. Configure Environment

Create a `.env` file based on `.env.example`:

```bash
cp .env.example .env
```

Update the variables according to your setup (see below).

### 3. Run with Docker Compose

```bash
docker-compose up -d --build
```

> Ensure `/mnt/srv/docker` (your Docker data) and `/mnt/srv/Mega` (your mounted cloud storage) are available on your host.

---

## ⚙️ Environment Variables

| Variable             | Description                                         |
| -------------------- | --------------------------------------------------- |
| `TZ`                 | Timezone (e.g. `Europe/Paris`)                      |
| `GPG_PASSWORD`       | Password used to encrypt `.tar.gz` files            |
| `TELEGRAM_BOT_TOKEN` | (Optional) Token for Telegram bot                   |
| `TELEGRAM_CHAT_ID`   | (Optional) Chat ID to notify                        |
| `EMAIL_HOST`         | SMTP server                                         |
| `EMAIL_PORT`         | SMTP port (e.g. `587`)                              |
| `EMAIL_USER`         | Email login username                                |
| `EMAIL_PASS`         | Email password                                      |
| `EMAIL_TO`           | Destination email                                   |
| `CRON_SCHEDULE`      | Cron format (default: `30 1 * * *` = 1:30 AM daily) |
| `MAX_BACKUPS`        | Number of backups to retain (default: `4`)          |

> At least one notification method (Telegram or Email) is required.

---

## 📦 Backup Details

* Backup is saved as `backup-YYYYMMDD_HHMMSS.tar.gz.gpg`
* Contents:

  * `/mnt/srv/docker/container/` (read-only bind mount)
  * `/mnt/srv/docker/compose/docker-compose.yml`

---

## 🧪 Logs

* Stored in `/mnt/srv/docker/logs/backup/backup.log`
* Format:

  ```
  [YYYY-MM-DD HH:MM:SS TZ] [INFO] Message
  ```

---

## 🛠 Build with GitHub Actions

Docker image is built and pushed to GitHub Container Registry (`ghcr.io`) on every push to `main`.

### 🔧 Setup

1. Replace `<your-username>` in `.github/workflows/build.yml`
2. Create a secret in GitHub:

   * `GIT_TOKEN` → A GitHub Personal Access Token with `packages: write`

---

## 📤 Telegram Example

Use [@BotFather](https://t.me/BotFather) to create a bot and get:

* `TELEGRAM_BOT_TOKEN`
* Your `TELEGRAM_CHAT_ID` (via [@userinfobot](https://t.me/userinfobot))

---

## 📧 Email Example (msmtp)

The container uses `msmtp` for lightweight email sending. Logs stored in `/logs/msmtp.log`.

---

## 🧼 Backup Rotation

The script keeps only the **last N backups** (`MAX_BACKUPS`). Older encrypted `.tar.gz.gpg` files are deleted automatically.

---

## 🧩 Volumes Required

| Host Path                     | Container Path | Purpose              |
| ----------------------------- | -------------- | -------------------- |
| `/mnt/srv/docker`             | `/data`        | Docker config source |
| `/mnt/srv/Mega`               | `/backups`     | Cloud destination    |
| `/mnt/srv/docker/logs/backup` | `/logs`        | Logs directory       |

---

## 🧳 License

MIT License

---

## ✍️ Author

**Your Name**
GitHub: [@<your-username>](https://github.com/<your-username>)

```

---

Let me know if you'd like me to:
- Replace placeholders with your GitHub username
- Add badges (Docker Hub, GitHub Actions)
- Translate to French or another language
- Add screenshots of logs or sample Telegram messages
