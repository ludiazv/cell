# Cell: Is a base image programatic containters.
# Debian wheezy + minimal tools + confd tool for coreos etcd auto-config
FROM debian:wheezy
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# update and install basic tools if needed
RUN apt-get update -qy && apt-get install -qy procps nano tar bzip2 wget net-tools adduser curl && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/*

# ADD CONFD binary and create condf directories
ADD confd-0.8.0-linux-amd64 /usr/local/bin/confd
RUN chmod u=rwx,g=rx,o=rx /usr/local/bin/confd && mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates
ADD confd.toml /etc/confd/confd.toml
	

# ADD gosu
ADD gosu-amd64-1.2 /tmp/gosu
RUN chmod u=rwx,g=rx,o=rx /tmp/gosu && mv /tmp/gosu /usr/local/bin/gosu

# ADD files
RUN mkdir -p /opt/confcell
ADD confcell.sh /opt/confcell/confcell.sh 
ADD cell_entry.sh /opt/cell_entry.sh 
RUN chmod u=rwx,g=rx,o=r /opt/confcell/confcell.sh && chmod u=rwx,g=rx,o=r /opt/cell_entry.sh

ENTRYPOINT ["/opt/cell_entry.sh"]
