
#!/bin/bash
set -euxo pipefail

apt-get update
apt-get install -y docker.io git mysql-client

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu

cd /home/ubuntu

git clone "${github_repo}" bus-ticket-app
cd bus-ticket-app

docker build -t gobus:v1 .

# Wait until RDS accepts connections
for i in $(seq 1 60); do
    if mysqladmin ping \
      -h "${db_host}" \
      -P 3306 \
      -u "${db_user}" \
      --password="${db_password}" \
      --connect-timeout=5 --silent; then
        break
    fi
    sleep 10
done

mysqladmin ping \
  -h "${db_host}" \
  -P 3306 \
  -u "${db_user}" \
  --password="${db_password}" \
  --connect-timeout=5

# Initialize database tables and sample data once
mysql \
  -h "${db_host}" \
  -P 3306 \
  -u "${db_user}" \
  --password="${db_password}" \
  "${db_name}" < schema.sql

# Run application container
docker run -d \
  --name gobus-app \
  --restart unless-stopped \
  -p 5000:5000 \
  -e DB_HOST="${db_host}" \
  -e DB_USER="${db_user}" \
  -e DB_PASSWORD="${db_password}" \
  -e DB_NAME="${db_name}" \
  -e DB_PORT=3306 \
  gobus:v1
-e ADMIN_USERNAME="${admin_username}" \
-e ADMIN_PASSWORD="${admin_password}" \
-e SECRET_KEY="${app_secret_key}" \