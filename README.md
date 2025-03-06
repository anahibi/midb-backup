# midb-backup

Misskeyのデータベースをバックアップし、結果をDiscordへ通知するシェルスクリプトです。  

## 必要なもの

事前にs3cmdをインストールし、設定ファイル( `/root/.s3cfg` )を作成してください。

## 使い方

.envファイルを作成し、環境変数を設定します。

```
cp .env.example .env
```

環境変数を読み込んで実行します。  
おそらくroot権限が必要です。

```
source .env
bash backup.sh
```

## cronの設定例

cronを用いて定期実行する例です。

```
0 3 * * * . /root/midb-backup/.env && /root/midb-backup/backup.sh
```