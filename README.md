# midb-backup

Misskeyのデータベースをバックアップするシェルスクリプトです。  
s3cmdのインストールが必要です。

環境変数を設定します。

```
cp .env.example .env
```

読み込んで実行します。

```
source .env
bash backup.sh
```

cronの設定例です。

```
0 3 * * * . /root/midb-backup/.env && /root/midb-backup/backup.sh
```