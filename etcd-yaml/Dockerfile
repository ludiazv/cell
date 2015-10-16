# Container for etcd-yaml
FROM atlo/ruby2
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

# install gpg2
USER root
RUN apt-get update -yq && apt-get install gnupg2 -yq && apt-get autoclean && apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

VOLUME ["/opt/keys"]

USER cell
RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm && gem install etcd net-ssh net-ssh-gateway --no-ri --no-rdoc"

COPY etcd-yaml.rb /opt/ruby_run/etcd-yaml.rb

ENTRYPOINT ["/opt/ruby_entry.sh","/opt/ruby_run/etcd-yaml.rb"]
