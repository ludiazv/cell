#!/bin/sh
PREFIX="/"
ETS="etcdctl set $PREFIX/nginx/"
etcdctl mkdir $PREFIX/nginx

# Config dir
etcdctl mkdir $PREFIX/nginx/conf
# Upstreams dir
etcdctl mkdir $PREFIX/nginx/upstreams
# Sites dir
etcdctl mkdir $PREFIX/nginx/sites
# Maintenance mode dir
etcdctl mkdir $PREFIX/nginx/maintenance

# ---- Conf -----
$ETS conf/worker_processes 'auto'
$ETS conf/worker_rlimit_nofile 1000000
$ETS conf/worker_connections 1204
$ETS conf/events 'multi_accept on; use epoll;'

# ---- http ----
$ETS conf/index 'index.php index.html index.htm;'
read -r -d '' HTTP_CONF <<-EOF
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

EOF

$ETS conf/http-conf "$HTTP_CONF"









	# Caches information about open FDs, freqently accessed files.
	#open_file_cache both turns on cache activity and specifies the maximum number 
	#of entries in the cache, along with how long to cache them. We’ll set our maximum
	#to a relatively high number, and we’ll get rid of them from the cache if they’re inactive
	#for 20 seconds. Can boost performance, but you need to test those values
	# 	open_file_cache max=65000 inactive=20s;
	#open_file_cache_valid specifies interval for when to check the validity of the information about the item in open_file_cache.	
	# 	open_file_cache_valid 30s;
	#open_file_cache_min_uses defines the minimum use number of a file within the 
	#time specified in the directive parameter inactive in open_file_cache.	
	#	 open_file_cache_min_uses 2;
	#open_file_cache_errors specifies whether or not to cache errors when searching for a file.
	#	 open_file_cache_errors on;

	#Configuracion del proxy cache
	#Verificar que existe estructura y una vez creada darle permisos al usuario nginx:  "chown nginx:nginx /var/blahblah"
	#Hay que pasar en los server o location un "proxy_cache zona_uno;"
	proxy_buffering           on;
        proxy_cache_valid         any 10m;
        proxy_cache_path          /var/www/cache levels=1:2 keys_zone=zona_uno:8m max_size=1000m inactive=600m;
        proxy_temp_path           /var/www/cache/tmp;
        proxy_buffer_size         4k;
        proxy_buffers             100 8k;
	proxy_connect_timeout      60;
	proxy_send_timeout         60;
	proxy_read_timeout         60;

	# Load modular configuration files from the /etc/nginx/conf.d directory.
	include /etc/nginx/conf.d/*.conf;
	index   index.php index.html index.htm;

}


