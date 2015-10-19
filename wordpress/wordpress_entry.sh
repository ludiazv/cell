#!/bin/bash

WP="gosu nginx wp --path=/opt/nginx/sites/wordpress "

# Manage DB parameters at boot
source /opt/wordpress_fetch_params.sh
fetch_mysql
[ $? -ne 0 ] && exit 1

# Complete nginx parameters for wordpress with wordpress values
echo "Configuring nginx for wordpress...."
etcdctl_present "nginx/conf/events"
[ $? -ne 0 ] && etcdctl_set "nginx/conf/events" "multi_accept on; use epoll;"
etcdctl_present "nginx/conf/index"
[ $? -ne 0 ] && etcdctl_set "nginx/conf/index" "index.php index.html index.htm"
etcdctl_present "nginx/conf/httpconf"
[ $? -ne 0 ] && etcdctl_set "nginx/conf/httpconf" "include /etc/nginx/wordpress_http.conf;"
etcdctl_present "nginx/sites/site-wordpress/extra_locations"
[ $? -ne 0 ] && etcdctl_set "nginx/sites/site-wordpress/extra_locations" "include /etc/nginx/wordpress_site.conf;"
echo "done"

# One time config for assure that the conf files are ready
confd -onetime -node="http://$HOST_IP:2379" -prefix="$CELL_ETCD_PREFIX"

# --- Installation of word press ---
# Try to create db if not exits
$WP db create 
# Install if not installed
$WP core is-installed
if [ $? -ne 0 ] ; then
 	echo "Wordpress not initialized... preparing installation."
 	wpuser=$(etcd_get "wordpress_conf/wp-admin" 	"wp-admin")
 	wpupwd=$(crypt_get "wordpress_conf/wp-admin-pwd"	"wp-admin")
 	wpdom=$(etcd_get "wordpress_conf/wp-domain"	"http://www.sample.com")
 	wptitle=$(etcd_get "wordpress_conf/wp-title"	"Atlo sample wordpress site")
 	wpemail=$(etcd_get "wordpress_conf/wp-admin-pwd" "wp-admin")
 	$WP core install --url="${wpdom}" --title="${wptile}" --admin_user="${wpuser}" --admin_password="${wpupwd}" --admin_email="${wpemail}"
fi
echo "Version of wordpress installed $($WP core version)..."

/opt/nginx_entry.sh

exit 0
# Run nginx+PHP-FPF
#/opt/nginx_entry.sh
