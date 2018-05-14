# proxysql
Docker image with ProxySQL 1.4.8 based on Phusion base image for ubuntu with mysql client included to connect to proxySQL admin interface using port 6032

Usage:

docker exec -it <container_id/name> mysql -h127.0.0.1 -u admin -p -P6032

rest follow ProxySQL documentation. 