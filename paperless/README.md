# Paperless Ngx

Document management system for organizing, indexing, and searching your documents.

## Installation

Enable Paperless by setting `COMPOSE_PROFILES=paperless`.

Paperless will be accessible at `/paperless`.

On first run, an admin account will be created with the credentials specified in `paperless/.env`.

## Environment Variables

| Variable                   | Description                                     | Default         |
|----------------------------|-------------------------------------------------|-----------------|
| `PAPERLESS_SECRET_KEY`     | Secret key for production, generate with `openssl rand -base64 32` | |
| `PAPERLESS_TIME_ZONE`      | Timezone for the container                      | `America/New_York` |
| `PAPERLESS_OCR_LANGUAGE`   | Default OCR language                            | `eng`           |
| `PAPERLESS_ADMIN_USER`     | Admin username                                  | `admin`         |
| `PAPERLESS_ADMIN_PASSWORD` | Admin password                                  | `changeme`      |

## Backup

Paperless data can be backed up to any cloud storage product using [Restic](https://restic.readthedocs.io/) via [resticker](https://github.com/djmaze/resticker).

Restic provides:
- **Incremental backups**: Only changed data is backed up
- **Deduplication**: Identical content across snapshots uses minimal space
- **Encryption**: All data encrypted with your repository password
- **Compression**: Optional, doesn't interfere with deduplication
- **Remote backends**: S3, B2, SFTP, Rclone remotes, and more

### What Gets Backed Up

- **Data directory** (`/usr/src/paperless/data`): SQLite database and settings
- **Media directory** (`/usr/src/paperless/media`): Documents, thumbnails, and attachments

### What Is Excluded

- **Thumbnails** (`/data/media/.thumbnails/`): Can be regenerated

### Initial Setup

#### 1. Configure Backup Environment

Copy the backup environment template and customize it:

```bash
cp paperless/backup.env.example paperless/backup.env
```

Edit `paperless/backup.env` and set the following:

| Variable              | Description                                   | Example                    |
|-----------------------|-----------------------------------------------|----------------------------|
| `RESTIC_REPOSITORY`   | Backup destination URI for Restic             | See examples below         |
| `RESTIC_PASSWORD`     | Strong password to encrypt the repository     | Generate with `openssl rand -base64 32` |
| `CRON`                | Backup schedule (cron format with seconds)     | `0 30 3 * * *` (3:30 AM daily) |
| `TIMEZONE`            | Timezone for cron scheduling                  | `America/New_York`         |
| `RESTIC_FORGET_ARGS`  | Backup retention policy                       | `--keep-last 7 --keep-daily 7 --keep-weekly 4 --keep-monthly 3` |

#### 2. Choose Your Backup Destination

Restic supports multiple backends. Pick one based on your infrastructure:

**Rclone Remote** (Optional - reuse existing rclone configuration):

Rclone is optional. Use this only if your `RESTIC_REPOSITORY` URI starts with `rclone:`. If you prefer to use Rclone, it allows you to back up to any service supported by Rclone (S3, B2, SFTP, Google Drive, OneDrive, Dropbox, etc.) without direct Restic support, or if you want to reuse existing Rclone configurations.

First, configure your rclone remote destination:

```bash
docker compose run --rm -it paperless-backup rclone config
```

This interactive command will guide you through:
1. Creating a new remote (choose `n`)
2. Naming your remote (e.g., `backup-s3`, `backup-b2`, `backup-sftp`, etc.)
3. Selecting your storage type (S3, B2, SFTP, etc.)
4. Entering credentials and configuration

The configuration will be saved to `paperless/.rclone/rclone.conf`. Do not manually edit this file; use the `rclone config` command above to modify it.

Then set in `backup.env`:

```bash
RESTIC_REPOSITORY=rclone:myremote:/nas-backups/paperless
```

This allows you to use any rclone-supported backend seamlessly.

**S3-Compatible (Direct)** (AWS, Wasabi, MinIO, DigitalOcean Spaces, etc. - no Rclone needed):

You can also back up directly to S3-compatible services without using Rclone:

```bash
# Set in backup.env:
RESTIC_REPOSITORY=s3:s3.amazonaws.com/my-bucket/paperless

# Or for S3-compatible services:
RESTIC_REPOSITORY=s3:https://s3.wasabisys.com/my-bucket/paperless

# Additional environment variables:
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
```

**Backblaze B2** (Direct - no Rclone needed):
```bash
# Set in backup.env:
RESTIC_REPOSITORY=b2:my-bucket:paperless

# And provide credentials:
B2_ACCOUNT_ID=your_account_id
B2_ACCOUNT_KEY=your_account_key
```

**SFTP** (Direct - no Rclone needed):
```bash
# Set in backup.env:
RESTIC_REPOSITORY=sftp://user@backup.example.com/paperless

# Password authentication is interactive or set:
SFTP_PASSWORD=your_sftp_password
```

**Local Path** (NAS mounted volume or local directory - no Rclone needed):
```bash
# Set in backup.env:
RESTIC_REPOSITORY=/mnt/backup-drive/paperless

# Ensure the directory exists and is writable:
mkdir -p /mnt/backup-drive/paperless
```

**Google Cloud Storage** (Direct - no Rclone needed):
```bash
# Set in backup.env:
RESTIC_REPOSITORY=gs://my-bucket/paperless

# And provide credentials (via service account JSON):
GOOGLE_APPLICATION_CREDENTIALS=/path/to/credentials.json
```

**Azure Blob Storage** (Direct - no Rclone needed):
```bash
# Set in backup.env:
RESTIC_REPOSITORY=azure://paperless-container/paperless

# And provide credentials:
AZURE_ACCOUNT_NAME=myaccount
AZURE_ACCOUNT_KEY=mykey
```

#### 3. Generate a Secure Password

```bash
# Generate a strong random password
openssl rand -base64 32

# Copy the output and paste it into backup.env as RESTIC_PASSWORD
```

**Important**: Store this password securely. You'll need it to restore backups. If lost, your backup data becomes inaccessible.

### Testing the Backup

#### List Existing Snapshots

```bash
docker compose run --rm paperless-backup snapshots
```

This will list all backup snapshots. If the repository doesn't exist yet, it will be initialized automatically on the first scheduled backup.

#### Manually Trigger a Backup

Perform a one-time backup:

```bash
docker compose run --rm paperless-backup backup /data
```

Then apply the retention policy to clean up old snapshots:

```bash
docker compose run --rm paperless-backup forget --prune --keep-last 7 --keep-daily 7 --keep-weekly 4 --keep-monthly 3
```

(Note: Replace the `--keep-*` arguments with your configured `RESTIC_FORGET_ARGS` from `backup.env`)

#### Check Repository Status

```bash
docker compose run --rm paperless-backup check
```

#### Monitor Scheduled Backups

Start the Paperless backup service:

```bash
COMPOSE_PROFILES=paperless,paperless-backup docker compose up -d
```

Then monitor backup logs:

```bash
docker compose logs -f paperless-backup
```

The backup will run automatically according to the schedule in `backup.env` (default: 3:30 AM daily).

### Restoration

#### Quick restore overview:

1. Stop the Paperless service
2. Restore the SQLite database from the Restic snapshot
3. Restore the media directory from the Restic snapshot
4. Start Paperless again

To restore a specific snapshot:

```bash
docker compose run --rm paperless-backup restore <snapshot-id> --target /restored
```

Then:
1. Copy the database: `cp /restored/paperless.db /restored/data/paperless.db`
2. Copy the media: `cp -r /restored/media/* paperless-media/`
3. Restart Paperless
