# Cell container with memcached
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

# update and install basic tools if needed & create cell user+group
RUN apt-get update -qy && apt-get install -qy netcat memcached && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/*

# Expose mc port
EXPOSE 11211

ENTRYPOINT ["/opt/memcached_entry.sh"]

# add entry
ADD memcached_entry.sh /opt/memcached_entry.sh
RUN chmod u=xrw,g=rx,o=rx /opt/memcached_entry.sh 






