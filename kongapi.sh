# !/bin/sh

wget https://download.konghq.com/gateway-3.x-ubuntu-focal/pool/all/k/kong/kong_3.5.0_amd64.deb
no-check-certificate
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt-get -y install postgresql

systemctl status postgresql

sudo -u postgres psql << EOF
CREATE USER kong WITH PASSWORD 'super_secret';
CREATE DATABASE kong OWNER kong;
\q
EOF

dpkg -i kong_3.5.0_amd64.deb
# $ apt get install -y zlib1g-dev

cd /etc/kong/
cp kong.conf.default kong.conf
echo "admin_listen = 0.0.0.0:8001 reuseport backlog=16384, 0.0.0.0:8444 http2 ssl reuseport backlog=16384" >> kong.conf
echo "database = postgres" >> kong.conf
echo "pg_host = 127.0.0.1" >> kong.conf
echo "pg_port = 5432" >> kong.conf
echo "pg_user = kong" >> kong.conf
echo "pg_password = super_secret" >> kong.conf
echo "pg_database = kong" >> kong.conf 

kong migrations bootstrap
kong start
cd /home/deb/

curl --head localhost:8001

sleep 5
curl -i -X POST --url http://localhost:8001/services/ --data 'name=connectIAF-service' --data 'url=http://localhost:5006/connectIAF' 
curl -i -X POST --url http://localhost:8001/services/connectIAF-service/routes --data 'paths[]=/connectIAF'

sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=registerApp-service' --data 'url=http://localhost:5005/registerApp'
curl -i -X POST --url http://localhost:8001/services/registerApp-service/routes --data 'paths[]=/registerApp'
curl -i  -X PATCH --url http://localhost:8001/services/registerApp-service --data 'connect_timeout=80000'
sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=registerNewVehiclePart-service' --data 'url=http://localhost:5000/registerNewVehiclePart'
curl -i -X POST --url http://localhost:8001/services/registerNewVehiclePart-service/routes --data 'paths[]=/registerNewVehiclePart'

sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=getVehicleAppStatus-service' --data 'url=http://localhost:5001/getVehicleAppStatus'
curl -i -X POST --url http://localhost:8001/services/getVehicleAppStatus-service/routes --data 'paths[]=/getVehicleAppStatus'

sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=download_certificate-service' --data 'url=http://localhost:5006/download_certificate' 
curl -i -X POST --url http://localhost:8001/services/download_certificate-service/routes --data 'paths[]=/download_certificate'

sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=ota_server-service' --data 'url=http://localhost:5004/ota_server' 
curl -i -X POST --url http://localhost:8001/services/ota_server-service/routes --data 'paths[]=/ota_server'

sleep 1
curl -i -X POST --url http://localhost:8001/services/ --data 'name=run_microservice-service' --data 'url=http://localhost:5005/run_microservice' 
curl -i -X POST --url http://localhost:8001/services/run_microservice-service/routes --data 'paths[]=/run_microservice'
