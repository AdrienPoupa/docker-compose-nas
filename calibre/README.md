# Calibre Content Server & CalibreWeb

The calibre Content server allows you to manage, import, convert and curate your ebook collection / calibre database.
CalibreWeb is a browser ebook reader with very nice searching and user management capabilities.

You could enable only CalibreWeb and use a it on an existing calibre library. To use Readarr, you'll need Calibre Content Server.

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
