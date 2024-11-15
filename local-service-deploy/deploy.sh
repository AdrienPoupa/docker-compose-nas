#!/usr/bin/env bash
cd "$(dirname "$0")"

DEPLOY_TARGET_DIR='/etc/docker/compose/docker-compose-nas/'

echo "stopping media server"
systemctl stop docker-compose@docker-compose-nas

echo "Copy all systemd scripts to target directory"
sudo cp -R systemd /etc/

sudo mkdir -p "$DEPLOY_TARGET_DIR"

cp ../docker-compose.yaml "${DEPLOY_TARGET_DIR}"
cp ../.env "${DEPLOY_TARGET_DIR}"

echo "Reloading systemd units"
systemctl daemon-reload

echo "Starting media server back up"
systemctl start docker-compose@docker-compose-nas

# should be idempotent commands.
systemctl start docker-cleanup.service
systemctl start docker-cleanup.timer

echo ".env file deployed as:"
cat "${DEPLOY_TARGET_DIR}/.env"
