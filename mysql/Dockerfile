# Cell container form mysql
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

ENV MYSQL_VERSION 5.6
# add msql user to assure 
RUN groupadd -g 2016 mysql && adduser  --uid 2016 --ingroup mysql --shell /bin/bash --gecos "" --disabled-password mysql

# Debian MYSQL
RUN apt-get update -qy && apt-get install -qy mysql-server && apt-get autoclean && apt-get clean && rm -rf /var/lib/apt/lists/* && rm -fr /var/lib/mysql/* && wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /opt/basic_passwords.txt && wget http://mysqltuner.pl/ -O /opt/mysqltuner.pl

# Install perl 
#RUN apt-get update -qy && apt-get install -yq perl --no-install-recommends && apt-get autoclean && #apt-get clean && rm -rf /var/lib/apt/lists/* && wget http://mysqltuner.pl/ -O /opt/mysqltuner.pl && wget https://raw.githubusercontent.com/major/MySQLTuner-perl/master/basic_passwords.txt -O /opt/basic_passwords.txt

# Install MYSQL + psql tunner
#RUN apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5 && echo "deb #http://repo.mysql.com/apt/debian/ wheezy mysql-5.5" > /etc/apt/sources.list.d/mysql.list && #apt-get update -qy && apt-get install -qy mysql-server && apt-get autoclean && apt-get clean #&& rm -rf /var/lib/apt/lists/* && rm -fr /var/lib/mysql/*

# Expose mysql port & declare volumen
EXPOSE 3306
VOLUME ["/opt/mysql-data","/opt/mysql-backup"]
ENTRYPOINT ["/opt/mysql_entry.sh"]

# Entry point & prepare data dir
ADD mysql_*.sh /opt/
RUN chmod u=xrw,g=rx,o=rx /opt/mysql_*.sh && mkdir -p /opt/mysql-data && \
	mkdir -p /opt/mysql-backup && chmod u=rwx,g=x /opt/mysql-data /opt/mysql-backup && \
	chown mysql:mysql /opt/mysql-data /opt/mysql-backup && chown mysql:mysql /etc/mysql/my.cnf

# ConfD files	
COPY my.toml /etc/confd/conf.d/my.toml
COPY my.cnf /etc/confd/templates/my.cnf.tmpl





