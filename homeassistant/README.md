# Home Assistant

Open source home automation that puts local control and privacy first. Powered by a worldwide community of tinkerers and DIY enthusiasts

## Installation

Enable Home Assistant by setting `COMPOSE_PROFILES=homeassistant`.

Set the `HOMEASSISTANT_HOSTNAME`, since it does not support
[running in a subfolder](https://github.com/home-assistant/architecture/issues/156).
Add the necessary DNS records in your domain.

You will need to allow Traefik to access Home Assistant by adding the following in `homeassistant/configuration.yaml`:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.0.0.0/8 # You can put a more precise range instead
```

Set the `HOMEASSISTANT_ACCESS_TOKEN` for homepage support.

## MQTT

If you need to use MQTT, you can enable it by setting `COMPOSE_PROFILES=homeassistant,mqtt`.

Start the container, create a user in mosquitto with the following command and the credentials defined previously:

`docker compose exec mosquitto mosquitto_passwd -b /mosquitto/config/pwfile <username> <password>`

Restart the Mosquitto container to apply the changes.

In HomeAssistant, add the MQTT integration with hostname `localhost`, port 1883 and the username and password defined above.

## Backup

### Enable Backups in HomeAssistant

We will create an automation that will create backups nightly and clear old ones.

Add a `command_line` inclusion in your `configuration.yaml`: `command_line: !include command_lines.yaml`

The `command_lines.yaml` defines a switch that removes backups older than 7 days:

```yaml
- switch:
    name: Purge old backups
    unique_id: switch.purge_backups
    icon: mdi:trash-can
    command_on: 'cd /config/backups/ && find . -maxdepth 1 -type f -mtime +7 -print | xargs rm -f'
```

Then, create an automation that will trigger backups nightly and call the purge old backups switch:

```yaml
alias: Backup Home Assistant every night at 3 AM
description: Backup Home Assistant every night at 3 AM
trigger:
  - platform: time
    at: "03:00:00"
action:
  - service: backup.create
    data: {}
  - service: switch.turn_on
    data: {}
    target:
      entity_id: switch.purge_old_backups
  - service: switch.turn_off
    data: {}
    target:
      entity_id: switch.purge_old_backups
mode: single
```

### Save Backups Remotely

Home Assistant can be backed up in the cloud storage product of your choice with [Rclone](https://rclone.org/).

Before a backup can be made, `rclone config` must be run to generate the configuration file:

```shell
docker compose run --rm -it homeassistant-backup rclone config
```

It will generate a `rclone.conf` configuration file in ./homeassistant/rclone/rclone.conf.

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
docker compose run --rm -it homeassistant-backup backup
```
