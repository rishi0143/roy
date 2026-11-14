
#!/bin/bash
set -eux

apt-get update
apt-get install -y nginx

cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://${backend_private_ip}:5000;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

nginx -t
systemctl enable nginx
systemctl restart nginx
