# Cell container With NGINX 1.8
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive
ENV NGINX_VERSION 1.8.0-1~wheezy

# Install nginx repository
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
	wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - && \
	apt-get update -qy && apt-get install nginx=${NGINX_VERSION} php5-fpm -qy && \
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* 

ADD nginx_entry.sh /opt/nginx_entry.sh
RUN chmod 755 /opt/nginx_entry.sh && mkdir -p /opt/nginx /opt/nginx/sites && chown -R nginx:nginx /opt/nginx

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

VOLUME ["/var/cache/nginx"]


# HTTP & HTTP SSL Ports
EXPOSE 80 443

ENTRYPOINT ["/bin/bash"]




