#!/bin/bash

BACKUP_DIR="/backup"
SOURCE_DIR="/var/log/nginx"
DATE=$(date +%Y-%m-%d)
FILENAME="log-backup-$DATE.tar.gz"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/$FILENAME" "$SOURCE_DIR"
find "$BACKUP_DIR" -name "log-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete