#!/bin/bash

# 引数チェック: -force フラグが指定された場合は実行する。
if [[ "$1" != "-force" ]]; then
  echo "Error: This script must be run with the -force flag to proceed."
  echo "Usage: $0 -force"
  exit 1
fi

# 最新のバックアップファイルpathを定義
restore_path=$(s3cmd ls s3://$SERVICE_NAME/$(date +%Y-%m-%d)/ |grep dump |head -n1 |cut -d " " -f7)
echo "restore_path: ${restore_path}"
# 最新のバックアップファイルを取得
s3cmd get ${restore_path} /tmp/misskey.dump.enc
# バックアップファイルを復号
openssl enc -d -aes-256-cbc -salt -pbkdf2 -in /tmp/misskey.dump.enc -out /tmp/misskey-dump.sql -k $ENCRYPTION_KEY
# バックアップファイルをDBにインポート
pg_restore --clean --if-exists --jobs=4 -h localhost -U "$POSTGRESQL_USER" -d "$POSTGRESQL_DB" /tmp/misskey-dump.sql
# バックアップファイルを削除
rm -f /tmp/misskey.dump.enc
rm -f /tmp/misskey-dump.sql
