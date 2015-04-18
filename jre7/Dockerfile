# debian wheezy + java 7u76 (based on Samuel nasello Dockerfile)
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# ADD JRE 
ADD jre-7u76-linux-x64.gz /tmp/jre
RUN mv /tmp/jre/jre1.7.0_76 /opt/jre1.7.0_76 && ln -s /opt/jre1.7.0_76 /opt/java \
    && update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1 \
	&& update-alternatives --set java /opt/java/bin/java \
	&& rm -fR /tmp/* && apt-get update -yq && apt-get install libjna-java -qy \
	&& rm -rf /var/lib/apt/lists/* && chown -R root:root /opt/jre1.7.0_76
	
# Set JAVA_HOME
ENV JAVA_HOME /opt/java