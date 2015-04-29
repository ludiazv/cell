# Cell container With NGINX 1.6
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Install nginx repository
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
	wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - && \
	apt-get update -qy && apt-get install nginx -qy && mkdir -p /etc/redis && \
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* 

# Scritp vm overcommit and max conections acording to redis 2.8 recommendations and add a volume
ADD nginx_entry.sh /opt/nginx_entry.sh
RUN chmod 755 /opt/redis_entry.sh && mkdir -p /opt/nginx /opt/nginx/sites && chown -R nginx:nginx /opt/nginx


# HTTP & HTTP SSL Ports
EXPOSE 80 443

ENTRYPOINT ["/bin/bash"]




