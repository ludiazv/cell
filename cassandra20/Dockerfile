FROM atlo/jre7
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Install phyton needed for cqlsh and OpsCenter
RUN apt-get update -qy && apt-get install -qy python2.6 && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install cassandra from tar file and create user for cassandra
#ADD dsc-cassandra-2.0.13-bin.tar.gz /opt

RUN wget --quiet -O - http://downloads.datastax.com/community/dsc-cassandra-2.0.14-bin.tar.gz | tar xz -C /opt 
RUN ln -s /opt/dsc-cassandra-2.0.14 /opt/cassandra && ln -s /opt/cassandra/bin /opt/casbin && \
	groupadd -g 1337 cassandra && \
    useradd  -u 1337 -g cassandra -s /bin/sh -d /opt/cassandra-data cassandra && \
	mkdir -p /opt/cassandra-log && \
	sed -i 's/^\(log4j\.appender\.R\.File=\).*/\1\/opt\/cassandra-log\/system.log/' /opt/cassandra/conf/log4j-server.properties && \
	mkdir -p /opt/cassandra-data/data && mkdir -p /opt/cassandra-data/commitlog && \
	mkdir -p /opt/cassandra-data/data/saved_caches && \
    chown -R cassandra:cassandra /opt/cassandra-data && \
	chown -R cassandra:cassandra /opt/cassandra && \
	chown -R cassandra:cassandra /opt/dsc-cassandra-2.0.14 && \
	chown -R cassandra:cassandra /opt/cassandra-log && chown -R cassandra:cassandra /opt/casbin

COPY jna-platform-4.1.0.jar /opt/dsc-cassandra-2.0.14/lib/jna-platform.jar
COPY jna-4.1.0.jar /opt/dsc-cassandra-2.0.14/lib/jna.jar

USER cassandra
# Declare data and log volumes
VOLUME ["/opt/cassandra-data","/opt/cassandra-log"]

USER root	
ENV CASSANDRA_HOME /opt/cassandra

# ADD entry & CONFD files
ADD cassandra_entry.sh /opt/cassandra_entry.sh
ADD cassandra_init.sh  /opt/cassandra_init.sh
ADD cassandra.yaml /etc/confd/templates/cassandra.yaml.tmpl
ADD cassandra-yaml.toml /etc/confd/conf.d/cassandra-yaml.toml	

# Storage Port, JMX, Thrift, CQL Native, OpsCenter Agent
EXPOSE 9000 9001 7199 9042 9160 61621
ENTRYPOINT ["/opt/cassandra_entry.sh"]



