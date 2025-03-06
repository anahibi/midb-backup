#!/bin/bash
set -eo pipefail
[ "${DEBUG:-false}" = "true" ] && set -x

log() {
  echo "$(date +%Y-%m-%d_%H:%M:%S): $1"
}

send_discord_notification() {
  local message="$1"
  local webhook_url="$DISCORD_WEBHOOK_URL"
  if [ -n "$webhook_url" ]; then
    curl -H "Content-Type: application/json" -X POST -d "{\"content\": \"$message\"}" "$webhook_url"
  fi
}

error_exit() {
  log "Error: $1"
  send_discord_notification "Error: $1"
  exit 1
}

# 必須環境変数のチェック
check_env() {
  local var_name="$1"
  if [ -z "${!var_name}" ]; then
    echo "Error: Environment variable $var_name is not set." >&2
    exit 1
  fi
}

check_env "SERVICE_NAME"
check_env "POSTGRESQL_USER"
check_env "PGPASSWORD"
check_env "POSTGRESQL_DB"
check_env "REDIS_DUMP_PATH"
check_env "DISCORD_WEBHOOK_URL"

# 設定
S3CFG_FILE="${S3CFG_FILE:-/root/.s3cfg}"
[ ! -f "$S3CFG_FILE" ] && { echo "Error: S3 config file $S3CFG_FILE not found." >&2; exit 1; }

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TEMP_DIR=$(mktemp -d "/tmp/backup-${SERVICE_NAME}-XXXXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT

BACKUP_SQL_FILE="$TEMP_DIR/${SERVICE_NAME}-${TIMESTAMP}.dump"
BACKUP_REDIS_FILE="$TEMP_DIR/${SERVICE_NAME}-${TIMESTAMP}.rdb"
S3_BASE_PATH="s3://$SERVICE_NAME/$(date +%Y-%m-%d)"

log "Starting backup for $SERVICE_NAME"

# PostgreSQLバックアップ
if ! /usr/bin/pg_dump -Fc -U "$POSTGRESQL_USER" -d "$POSTGRESQL_DB" > "$BACKUP_SQL_FILE"; then
  error_exit "Error: Failed to dump PostgreSQL database $POSTGRESQL_DB"
fi
if ! /usr/bin/s3cmd -c "$S3CFG_FILE" put "$BACKUP_SQL_FILE" "$S3_BASE_PATH/backup-${SERVICE_NAME}-${TIMESTAMP}.dump"; then
  error_exit "Error: Failed to upload PostgreSQL backup to S3"
fi

# Redisバックアップ
if ! cp -p "$REDIS_DUMP_PATH" "$BACKUP_REDIS_FILE"; then
  error_exit "Error: Failed to copy Redis dump from $REDIS_DUMP_PATH"
fi
if ! /usr/bin/s3cmd -c "$S3CFG_FILE" put "$BACKUP_REDIS_FILE" "$S3_BASE_PATH/backup-${SERVICE_NAME}-${TIMESTAMP}.rdb"; then
  error_exit "Error: Failed to upload Redis backup to S3"
fi

log "Backup completed successfully"
send_discord_notification "Backup for $SERVICE_NAME completed successfully"