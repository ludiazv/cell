# Cell container With NGINX 1.6
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Install dotdeb repository where redis 2.8 is located
RUN echo "deb http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
    echo "deb-src http://nginx.org/packages/debian/ wheezy nginx" | tee -a /etc/apt/sources.list.d/nginx.sources.list && \
	wget --quiet -O - http://nginx.org/keys/nginx_signing.key | apt-key add - && \
	apt-get update -qy && apt-get install nginx -qy && mkdir -p /etc/redis && \
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* 

# Scritp vm overcommit and max conections acording to redis 2.8 recommendations and add a volume
#ADD redis_entry.sh /opt/redis_entry.sh
#RUN chmod 755 /opt/redis_entry.sh && mkdir -p /opt/redis_data && chown -R redis:redis /opt/redis_data /var/lib/redis
#VOLUME /opt/redis_data

# CONFD configuration for redis.conf file
#ADD redis.toml /etc/confd/conf.d/redis.toml
#ADD redis.conf /etc/confd/templates/redis.conf.tmpl
#RUN chown -R redis:redis /etc/redis

# HTTP & HTTP SSL Ports
EXPOSE 80 443

ENTRYPOINT ["/bin/bash"]




