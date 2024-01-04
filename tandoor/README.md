# Tandoor

[Tandoor](https://tandoor.dev/) is a recipe manager that allows you to manage your ever growing collection of digital recipes.

## Installation

Enable Tandoor by setting `COMPOSE_PROFILES=tandoor`. It will be accessible at `/recipes`.

Copy the example environment file and edit as needed before running Tandoor: `cp tandoor/env.example tandoor/.env`.

## Backup

Tandoor's database and media files can be backed up in the cloud storage product of your choice with [Rclone](https://rclone.org/).

Before a backup can be made, `rclone config` must be run to generate the configuration file:

```shell
docker compose run --rm -it tandoor-backup rclone config
```

It will generate a `rclone.conf` configuration file in ./tandoor/rclone/rclone.conf.

Copy the backup environment file to `backup.env` and fill it as needed:
`cp backup.env.exmple backup.env`

| Variable             | Description                                                         | Default                   |
|----------------------|---------------------------------------------------------------------|---------------------------|
| `RCLONE_REMOTE_NAME` | Name of the remote you chose during rclone config                   |                           |
| `RCLONE_REMOTE_DIR`  | Name of the rclone remote dir, eg: S3 bucket name, folder name, etc |                           |
| `CRON`               | How often to run the backup                                         | `@daily` backup every day |
| `TIMEZONE`           | Timezone, used for cron times                                       | `America/New_York`        |
| `ZIP_PASSWORD`       | Password to protect the backup archive with                         | `123456`                  |
| `BACKUP_KEEP_DAYS`   | How long to keep the backup in the destination                      | `31` days                 |

You can test your backup manually with:

```shell
docker compose run --rm -it tandoor-backup backup
```
