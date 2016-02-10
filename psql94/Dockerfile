# Cell container postgresql 9.4
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Install psql repository from postgres respostity v9.4
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ wheezy-pgdg main" | tee -a /etc/apt/sources.list.d/psql.sources.list && \
	wget --quiet -O - http://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
	apt-get update -qy && apt-get install postgresql-9.4 -qy && apt-get autoclean && apt-get clean && \
	rm -rf /var/lib/apt/lists/* && \
	mkdir -p /opt/psql-data && chown -R postgres:postgres /opt/psql-data && \
	mkdir -p /opt/psql-backup && chown -R postgres:postgres /opt/psql-backup && \
	ln -s /usr/lib/postgresql/9.4/bin /opt/psqlbin && \
	mkdir -p /opt/psql-pid && chown -R postgres:postgres /opt/psql-pid

USER postgres
VOLUME ["/opt/psql-data","/opt/psql-backup"]
USER root

# CONFD configuration for redis.conf file
ADD postgresql.toml /etc/confd/conf.d/postgresql.toml
ADD postgresql.conf /etc/confd/templates/postgresql.conf.tmpl
ADD pg_hba.toml /etc/confd/conf.d/pg_hba.toml
ADD pg_hba.conf /etc/confd/templates/pg_hba.conf.tmpl

# ENV
ENV PGDATA /opt/psql-data
# Expose the PostgreSQL port
EXPOSE 5432
ENTRYPOINT ["/opt/psql_entry.sh"]

# Entrypoint
ADD psql_*.sh /opt/
RUN chmod u=xrw,g=rx,o=rx /opt/psql_*.sh




