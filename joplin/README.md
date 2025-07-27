# Joplin

[Joplin](https://joplinapp.org/) is an open source note-taking app. Capture your thoughts and securely access them from any device.

This service lets you host your own Joplin server, which your clients can connect to.

## Installation

Enable Joplin by setting `COMPOSE_PROFILES=joplin`. It will be accessible at `/joplin`.

Copy the example environment file and edit as needed before running Joplin: `cp joplin/env.example joplin/.env`.

## Backup

Joplin's database and media files can be backed up in the cloud storage product of your choice with [Rclone](https://rclone.org/).

Before a backup can be made, `rclone config` must be run to generate the configuration file:

```shell
docker compose run --rm -it joplin-backup rclone config
```

It will generate a `rclone.conf` configuration file in ./joplin/rclone/rclone.conf.

Copy the backup environment file to `backup.env` and fill it as needed:
`cp backup.env.exmple backup.env`

| Variable               | Description                                                         | Default                   |
|------------------------|---------------------------------------------------------------------|---------------------------|
| `MAILER_ENABLED`       | Enable Joplin mailer                                                | `false`                   |
| `MAILER_HOST`          | Mailer hostname                                                     |                           |
| `MAILER_PORT`          | Mailer port                                                         | `465`                     |
| `MAILER_SECURITY`      | Mailer security protocol                                            | `MailerSecurity.Tls`      |
| `MAILER_AUTH_USER`     | Mailer user                                                         |                           |
| `MAILER_AUTH_PASSWORD` | Mailer password                                                     |                           |
| `MAILER_NOREPLY_NAME`  | No reply email name                                                 |                           |
| `MAILER_NOREPLY_EMAIL` | No reply email address                                              |                           |
| `RCLONE_REMOTE_NAME`   | Name of the remote you chose during rclone config                   |                           |
| `RCLONE_REMOTE_DIR`    | Name of the rclone remote dir, eg: S3 bucket name, folder name, etc |                           |
| `CRON`                 | How often to run the backup                                         | `@daily` backup every day |
| `TIMEZONE`             | Timezone, used for cron times                                       | `America/New_York`        |
| `ZIP_PASSWORD`         | Password to protect the backup archive with                         | `123456`                  |
| `BACKUP_KEEP_DAYS`     | How long to keep the backup in the destination                      | `31` days                 |

You can test your backup manually with:

```shell
docker compose run --rm -it joplin-backup backup
```
