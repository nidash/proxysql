# proxysql
Docker image with ProxySQL 1.4.8 based on Phusion base image for ubuntu with mysql client included to connect to proxySQL admin interface using port 6032

Usage:

docker exec -it <container_id/name> mysql -h127.0.0.1 -u admin -p -P6032

If you need to configure proxySql using a file use the following

docker run -d --name proxysql -v ~/data:/tmp/data -v ~/.proxycfg.cfg:/etc/proxycfg.cfg nidash/proxysql



rest follow ProxySQL documentation. 