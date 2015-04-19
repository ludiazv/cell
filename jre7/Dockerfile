# debian wheezy + java 7u76 (based on Samuel nasello Dockerfile thx)
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# ADD JRE 
#ADD jre-7u76-linux-x64.gz /tmp/jre
RUN wget --progress=bar --no-check-certificate -O /tmp/jre.tar.gz --header "Cookie: oraclelicense=a" http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jre-7u80-linux-x64.tar.gz && tar -C /opt -xzf /tmp/jre.tar.gz
RUN chown -R root:root /opt/jre1.7.0_80 && ln -s /opt/jre1.7.0_80 /opt/java \
    && update-alternatives --install "/usr/bin/java" "java" "/opt/java/bin/java" 1 \
	&& update-alternatives --set java /opt/java/bin/java \
	&& rm -fR /tmp/* && apt-get update -yq && apt-get install libjna-java -qy apt-get autoclean && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* 
	
# Set JAVA_HOME
ENV JAVA_HOME /opt/java