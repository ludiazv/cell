# Cell container wordpress 4.3
FROM atlo/nginx
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

ENV WORDPRESS_VERSION="4.3.1" WORDPRESS_SHA1="b2e5652a6d2333cabe7b37459362a3e5b8b66221"

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
# Install wordpress + wp-cli
RUN apt-get update -qy && apt-get install mysql-client -qy && \
	apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* \
	&& curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& mkdir -p /opt/nginx/sites && tar -xzf wordpress.tar.gz -C /opt/nginx/sites/ \
	&& rm wordpress.tar.gz \
	&& chown -R nginx:nginx /opt/nginx/sites/ \
	&& curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& php wp-cli.phar --info --allow-root && chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp \
	&& rm -rf /opt/nginx/sites/sample && rm -f /opt/nginx/sites/wordpress/wp-config-sample.php

ENTRYPOINT ["/opt/wordpress_entry.sh"]
VOLUME ["/opt/nginx/sites/wordpress"]
COPY wp-config.toml /etc/confd/conf.d/wp-config.toml
COPY wp-config-template.php /etc/confd/templates/wp-config.php.tmpl
COPY wordpress_*.conf /etc/nginx/


COPY wordpress_*.sh /opt/
RUN chmod +x /opt/wordpress_*.sh
