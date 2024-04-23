# Calibre Content Server

The calibre Content server allows you to access your calibre libraries and read books directly in a browser on your favorite mobile phone or tablet device.

## Installation

Enable Calibre Content Server by setting `COMPOSE_PROFILES=calibre`.
Make sure to set both `CALIBRE_USER` and `CALIBRE_PASS` in the root .env file.

Once Calibre is running (through `docker compose up -d`), setup the same user/pass you defined in the env file: `docker compose exec calibre calibre-server --userdb /config/users.sqlite --manage-users`, then restart calibre `docker compose restart calibre`

### Existing Calibre Library

Adjust the volume mount to point to your existing Calibre Library
 - default `${DATA_ROOT}/media/books`

### Start new empty Library

Do nothing, a new empty library will be initialized in the volume.

## Use with Readarr

If you want to use Calibre with Readarr, make sure to follow the specific Readarr instruction so the library does not get destroyed.
