#!/usr/bin/env bash
cd "$(dirname "$0")"

DEPLOY_TARGET_DIR='/etc/docker/compose/docker-compose-nas/'

echo "stopping media server"
systemctl stop docker-compose@docker-compose-nas


cp ../docker-compose.yaml "${DEPLOY_TARGET_DIR}"
cp ../.env "${DEPLOY_TARGET_DIR}"

echo "Reloading systemd units"
systemctl daemon-reload

echo "Starting media server back up"
systemctl stop docker-compose@docker-compose-nas

# should be idempotent commands.
systemctl stop docker-cleanup.service
systemctl stop docker-cleanup.timer

echo ".env file deployed as:"
cat "${DEPLOY_TARGET_DIR}/.env"
