ATLO/NGINX Container
====================

###Configuration of nginx via etcd
The container must be configured using etcd-confd software. To configure it in a proper way the user of the image must create several keys in the etcd key-value directory as follows:

General config

 - prefix/nginx/conf/worker_processes:Number of worker processess.
 - prefix/nginx/conf/worker_rlimit_nofile:Limit of **rlimit** # of files.
 - prefix/nginx/conf/worker_connections:Connections per worker.
 - prefix/nginx/conf/events: Nginx configuration for 'events' section.
 - prefix/nginx/conf/index: list of index files.
 - prefix/nginx/http-conf: Nginx configuration for 'http' section.

Sites and locations
Nginx uses two major concepts to manage responses to request: Servers and locations. For configure the

Upstreams

To use nginx as Load balancer it is needed to define uptreams servers to which trafic will be proxied. To configure an upstream etcd values are econded in json as following:
 ```
 
 {address:"some address ip:port or unix socket",options:"some options"}
 
 ```

 Within the etcd directory nginx/upstream two kind of entries:
 

 - prefix/nginx/upstreams/server-[name]: Each sub key of this entry need to be a upstream json value. 
 - prefix/nginx/upstreams/key-[name]: Point to other etcd where upstream entries are stored. By design of confd this key is relative to prefix.
  
####Typical values (example configuration for linux):

**worker_process**:  auto;
**worker_connections**: 1024
**events**: 
```	 
	multi_accept on;
	use epoll; 
```

**index**: index.php index.html index.htm
**http_conf**:
```    	
   	# File and tcp tweaks
	sendfile on;
	tcp_nopush on;
	tcp_nodelay on;
	
	# MIME types
	include 	  /etc/nginx/mime.types;
	default_type  application/octet-stream;

	# Logs
	log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log off;
    error_log	/var/log/nginx/error.log crit;

    # Keep Alive, timeouts
    send_timeout 	20;
    keepalive_timeout 15s;
	reset_timedout_connection on;
    
    client_body_timeout 25;
	client_header_timeout 25;

    # Buffers
	client_body_buffer_size
	client_body_in_file_only off;
	
    # Gzip
    gzip on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_disable “msie6”;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
    gzip_vary off;

    # FD cache
    open_file_cache max=5500 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;
    
```