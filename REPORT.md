#Laporan Assesment - Destia Eka

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
       Docs: man:nginx(8)
    Process: 36501 ExecStartPre=/usr/sbin/nginx -t -q -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
    Process: 36503 ExecStart=/usr/sbin/nginx -g daemon on; master_process on; (code=exited, status=0/SUCCESS)
   Main PID: 36504 (nginx)
      Tasks: 2 (limit: 1023)
     Memory: 1.7M (peak: 1.9M)
        CPU: 16ms
     CGroup: /system.slice/nginx.service
             ├─36504 "nginx: master process /usr/sbin/nginx -g daemon on; master_process on;"
             └─36505 "nginx: worker process"

Apr 06 08:51:09 ubuntu-24 systemd[1]: Starting nginx.service - A high performance web server and a reverse proxy server...
Apr 06 08:51:09 ubuntu-24 systemd[1]: Started nginx.service - A high performance web server and a reverse proxy server.
```
- **Bukti**:
![nginx](/assetes/nginx.jpg)

## Security Hardening
- **UFW Status**: ![ufw-status](/assetes/ufw-status.jpg)
- **Login SSH**: ![permission-denied](/assetes/permission-denied.jpg)

## Containerization
FROM nginx:alpine
WORKDIR /usr/share/nginx/html
COPY index.html .
EXPOSE 80

```
agus-admin@ubuntu-24:/opt/app-test$ sudo docker ps
[sudo] password for agus-admin:
CONTAINER ID   IMAGE             COMMAND                  CREATED          STATUS          PORTS                                     NAMES
80a9ef1bcb06   app-test:latest   "/docker-entrypoint.…"   23 minutes ago   Up 23 minutes   0.0.0.0:8080->80/tcp, [::]:8080->80/tcp   app
```

! [containerization](/assetes/containerization.jpg)

## Automation
root@ubuntu-24:~# cat backup.sh
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
3. Replikasi database: apabila user melakukan operasi writer (insert, update, delete) maka request diarahkan ke database primary. namun apabila hanya operasi read (select) maka akan diarahkan ke database replica. kedua database tersebut akan saling melakukan sinkronisasi sehingga data keduanya akan konsisten