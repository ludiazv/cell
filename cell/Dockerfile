# Cell: Is a base image programatic containters.
# Debian wheezy + minimal tools + confd tool for coreos etcd auto-config
FROM debian:wheezy
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# update and install basic tools if needed & create cell user+group
RUN apt-get update -qy && apt-get install -qy procps nano tar bzip2 wget net-tools adduser curl && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* && groupadd -g 2015 cell && adduser  --uid 2015 --ingroup cell --shell /bin/bash --gecos "" --disabled-password cell

# ADD GOSU+CONFD+crypt binary and create condf directories
#ADD confd-0.10.0-linux-amd64 /usr/local/bin/confd
#ADD gosu-amd64-1.2 /usr/local/bin/gosu 
#ADD crypt-0.0.1-linux-amd64 /usr/local/bin/crypt
RUN wget -O /usr/local/bin/gosu https://github.com/tianon/gosu/releases/download/1.5/gosu-amd64 && \
	wget -O /usr/local/bin/crypt https://github.com/xordataexchange/crypt/releases/download/v0.0.1/crypt-0.0.1-linux-amd64 && \
	wget -O /usr/local/bin/confd  https://github.com/kelseyhightower/confd/releases/download/v0.10.0/confd-0.10.0-linux-amd64 && \
	chmod u=rwx,g=rx,o=rx /usr/local/bin/confd /usr/local/bin/crypt /usr/local/bin/gosu && mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates
ADD confd.toml /etc/confd/confd.toml

# ADD files
#RUN mkdir -p /opt/confcell
#ADD confcell.sh /opt/confcell/confcell.sh 
ADD cell_entry.sh /opt/cell_entry.sh 
RUN chmod u=rwx,g=rx,o=r /opt/cell_entry.sh
#chmod u=rwx,g=rx,o=r /opt/confcell/confcell.sh 

VOLUME ["/opt/cel-keyring"]

ENTRYPOINT ["/opt/cell_entry.sh"]
