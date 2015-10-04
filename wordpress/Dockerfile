# Cell container wordpress 4.3
FROM atlo/nginx
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

ENV WORDPRESS_VERSION="4.3.1" WORDPRESS_SHA1="b2e5652a6d2333cabe7b37459362a3e5b8b66221"

# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
	&& echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
	&& mkdir -p /opt/wordpress && tar -xzf wordpress.tar.gz -C /opt/wordpress/ \
	&& rm wordpress.tar.gz \
	&& chown -R nginx:nginx /opt/wordpress

