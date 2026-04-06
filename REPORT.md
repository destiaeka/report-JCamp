# Laporan Assesment - Destia Eka

## Troubleshooting
- **Masalah**: Terdapat kesalahan penulisan script pada file /etc/nginx/sites-enabled/default
- **Solusi**: 
```
root@ubuntu-24:/etc/nginx/sites-available# nano /etc/nginx/sites-enabled/default
# benahi typo
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    add_header X-Frame-Options "SAMEORIGIN";
}
root@ubuntu-24:~# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
root@ubuntu-24:~# systemctl restart nginx
root@ubuntu-24:~# systemctl status nginx
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/usr/lib/systemd/system/nginx.service; enabled; preset: enabled)
     Active: active (running) since Mon 2026-04-06 08:51:09 UTC; 4s ago
```
- **Bukti**:
![nginx](/assetes/nginx.jpg)

## Security Hardening
- **UFW Status**: allow port 6622(ssh), 80(http), 443(https)
![ufw-status](/assetes/ufw-status.jpg)
- **Login SSH**: apabila device tidak memiliki private key akan gagal
![permission-denied](/assetes/permission-denied.jpg)
- **Login SSH**: namun apabila device memiliki private key akan berhasil
![success](/assetes/ssh-succes.jpg)

## Containerization
```
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY index.html .
EXPOSE 80
```
```
agus-admin@ubuntu-24:/opt/app-test$ sudo docker ps
[sudo] password for agus-admin:
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                     NAMES
80a9ef1bcb06   app-test:latest   "/docker-entrypoint.…"   23 minutes ago   Up 23 minutes   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   app
```

![containerization](/assetes/containerization.jpg)

## Automation
root@ubuntu-24:~# cat backup.sh
```
#!/bin/bash

BACKUP_DIR="/backup"
SOURCE_DIR="/var/log/nginx"
DATE=$(date +%Y-%m-%d)
FILENAME="log-backup-$DATE.tar.gz"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/$FILENAME" "$SOURCE_DIR"
find "$BACKUP_DIR" -name "log-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete
root@ubuntu-24:~# crontab -l
 0 2 * * * /root/backup.sh
```

```
root@ubuntu-24:~# chmod +x backup.sh
root@ubuntu-24:~# ./backup.sh
tar: Removing leading `/' from member names
root@ubuntu-24:~# ls /backup
log-backup-2026-04-06.tar.gz
```

## Architecture Design
![arcitegtur](/assetes/traffic.jpg)

disini menggunakan beberapa teknologi tambahan yaitu
1. Load Balancer : digunakan untuk membagi traffic yang masuk ke server, sehingga selutuh traffic akan terbagi sama rata, tidak akan berat di 1 app saja
2. Auto Scalling : Apabila traffic sedang naik maka otomatis akan ada server baru(app) yang dibuat sama seperti server yang sudah ada, lalu apabila traffic sudah mulai menurun maka server tersebut akan terhapus sehingga tidak memakan terlalu banyak resource. 
3. Replikasi database: apabila user melakukan operasi writer (insert, update, delete) maka request diarahkan ke database primary. namun apabila hanya operasi read (select) maka akan diarahkan ke database replica. database tersebut akan saling melakukan sinkronisasi sehingga data keduanya akan konsisten
