# Cell container With NGINX 1.8
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV NGINX_VERSION 1.8.0-1~wheezy

# Install nginx repository & forward request and error logs to docker log collector
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
    echo "deb http://packages.dotdeb.org wheezy-php56 all" | tee -a /etc/apt/sources.list.d/php56.sources.list && \
    echo "deb-src http://packages.dotdeb.org wheezy-php56 all" | tee -a /etc/apt/sources.list.d/php56.sources.list && \
	wget --quiet -O- http://nginx.org/keys/nginx_signing.key | apt-key add - && \
	wget --quiet -O- http://www.dotdeb.org/dotdeb.gpg  | apt-key add - && \
	apt-get update -qy && apt-get install nginx=${NGINX_VERSION} php5-fpm php5-mysql -qy && \
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* && \
	ln -sf /dev/stdout /var/log/nginx/access.log && ln -sf /dev/stderr /var/log/nginx/error.log

# Tune php config files
COPY php-fpm.conf /etc/php5/php-fpm.conf
COPY www.conf /etc/php5/pool.d/www.conf
RUN chmod u=rw,g=r,o=r /etc/php5/php-fpm.conf /etc/php5/php-fpm.conf && \
	sed -i "s/^\(bind-address.*=\).*/\1${CELL_LOCAL_IP}/" 

VOLUME ["/var/cache/nginx"]


# HTTP & HTTP SSL Ports
EXPOSE 80 443

#ENTRYPOINT ["/opt/nginx_entry.sh"]
ENTRYPOINT ["/bin/bash"]

ADD nginx_entry.sh /opt/nginx_entry.sh
ADD nginx.toml /etc/confd/conf.d/nginx.toml
ADD nginx.conf /etc/confd/templates/nginx.conf.tmpl
RUN chmod 755 /opt/nginx_entry.sh && mkdir -p /opt/nginx /opt/nginx/sites && chown -R nginx:nginx /opt/nginx








