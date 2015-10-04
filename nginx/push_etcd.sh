#!/bin/sh
PREFIX="/"
etcdctl mkdir $PREFIX/nginx

# Config dir
etcdctl mkdir $PREFIX/nginx/conf

# Maintenance mode dir
etcdctl mkdir $PREFIX/nginx/maintenance



etcdctl set $PREFIX/nginx/conf/worker_processes 'auto'
etcdctl set $PREFIX/nginx/conf/worker_rlimit_nofile	1000000
etcdctl set $PREFIX/nginx/conf/error_log_level 'crit'

etcdctl set $PREFIX/nginx/conf/send_timeout 20
etcdctl set $PREFIX/nginx/conf/keepalive_timeout '15s'

etcdctl set $PREFIX/nginx/conf/gzip_comp_level 4
etcdctl set $PREFIX/nginx/conf/gzip_min_length 2048
etcdctl set $PREFIX/nginx/conf/gzip_proxied 'any' 



# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#user  nginx;
#pid   /var/run/nginx.pid;

#worker_processes defines the number of worker processes that nginx should use
#when serving your website. The optimal value depends on many factors including
#(but not limited to) the number of CPU cores, the number of hard drives that store
#data, and load pattern. When in doubt, setting it to the number of available CPU
#cores would be a good start (the value “auto” will try to autodetect it).
#worker_processes 1;

#worker_rlimit_nofile changes the limit on the maximum number of open files
#for worker processes. If this isn’t set, your OS will limit. Chances are your OS
#and nginx can handle more than ulimit -n will report, so we’ll set this high so
#nginx will never have an issue with “too many open files”. Make sure to update
#these values on your OS, also.
#worker_rlimit_nofile 200000;
 
#events {
	# Determines how many clients will be served by each worker process.
	# (Max clients = worker_connections * worker_processes)
	# "Max clients" is also limited by the number of socket connections available on the system (~64k)
	#Since we bumped up worker_rlimit_nofile, we can safely set this pretty high.
#	worker_connections 1024;

	# Accept as many connections as possible, after nginx gets notification about a new connection.
	# May flood worker_connections, if that option is set too low.
#	multi_accept on;

	#use sets which polling method we should use for multiplexing clients on
	#to threads. If you’re using Linux 2.6+, you should use epoll. If you’re using 
	#*BSD, you should use kqueue. Alternatively, if you don’t include this 
	#parameter nginx will choose for you.
#	use epoll;

#}

http {
	# Sendfile copies data between one FD and other from within the kernel.
	# More efficient than read() + write(), since the requires transferring data to and from the user space.
#	sendfile on; 
	
	# Tcp_nopush causes nginx to attempt to send its HTTP response head in one packet,
	# instead of using partial frames. This is useful for prepending headers before calling sendfile,
	# or for throughput optimization.
#	tcp_nopush on;
	
	# don't buffer data-sends (disable Nagle algorithm). Good for sending frequent small bursts of data in real time.
	#tcp_nodelay tells nginx not to buffer data and send data in small, short bursts
	#– it should only be set for applications that send frequent small bursts of information
	#without getting an immediate response, where timely delivery of data is required.	 
#	tcp_nodelay on;

#	log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
#                      '$status $body_bytes_sent "$http_referer" '
#                      '"$http_user_agent" "$http_x_forwarded_for"';

#	include       /etc/nginx/mime.types;
#	default_type  application/octet-stream;

	#keepalive_timeout assigns the timeout for keep-alive connections with the client.
	#The server will close connections after this time. We’ll set it low, since we can
	#only open up so many file descriptors (connections) at once.	
	keepalive_timeout 20;
	 
	# Number of requests a client can make over the keep-alive connection. This is set high for testing.
	keepalive_requests 100000;

	# send the client a "request timed out" if the header is not loaded by this time. Default 60.
	client_header_timeout 20;
	
	# send the client a "request timed out" if the body is not loaded by this time. Default 60.
	client_body_timeout 20;	
  
	#reset_timedout_connection tells nginx to close connections on non-responding clients. 
	#This will free up all memory associated with that client.
	reset_timedout_connection on;

	#send_timeout specifies the response timeout to the client. 
	#This timeout does not apply to the entire transfer, but between two
	#subsequent client-read operations. If the client has not read any data 
	#for this amount of time, then nginx shuts down the connection. Default 60.
	send_timeout 20;
 
	# Compression. Reduces the amount of data that needs to be transferred over the network
	#gzip tells nginx to gzip the data we’re sending. This will reduce the amount of data we need to send.
	gzip on;
	#gzip_proxied allows or disallows compression of a response based on the request/response. 
	#We’ll set it to any, so we gzip all requests.
	#Otra opcion:  gzip_proxied expired no-cache no-store private auth;
	# ver: http://nginx.org/en/docs/http/ngx_http_gzip_module.html#gzip_proxied
	gzip_proxied any;
	#gzip_min_length sets the minimum number of bytes necessary for us to gzip data. 
	#If a request is under 1024  bytes, we won’t bother gzipping it, since gzipping does
	#slow down the overall process of handling a request.
	gzip_min_length 1024;
	#gzip_comp_level sets the compression level on our data. 
	#These levels can be anywhere from 1 to 9, 9 being the slowest but most compressed.
	#We’ll set it to 4, which is a good middle ground.
	gzip_comp_level 4;
	#gzip_types sets the type of data to gzip. There are some above, but you can add more.	
	gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
	#gzip_disable Disables gzipping of responses for requests with “User-Agent” header
	#fields matching any of the specified regular expressions.
	#The special mask “msie6” corresponds to the regular expression 
	#“MSIE [4-6]\.”, but works faster. Starting from version 0.8.11, 
	#“MSIE 6.0; ... SV1” is excluded from this mask. 
	#gzip_disable “msie6”;

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


