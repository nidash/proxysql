# proxysql
Docker image with ProxySQL 1.4.8 based on Phusion base image for ubuntu with mysql client included to connect to proxySQL admin interface using port 6032

Usage:
docker run -d --name proxysql -v ~/data:/tmp/data -v proxysql.cnf:/etc/proxysql.cnf nidash/proxysql

to logon to the ProxySQL admin interface use
docker exec -it <container_id/name> -h127.0.0.1 -u admin -p -P6032

rest follow ProxySQL documentation. 