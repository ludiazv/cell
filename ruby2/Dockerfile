# Cell container with RMV and ruby2 + git
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Do an update for packages let temporarly sudo for building installing
RUN apt-get update -yq && apt-get install git sudo -yq && apt-get autoclean && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* && echo "cell  ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

USER cell
# add keys and installs RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \curl -sSL https://get.rvm.io | bash -s stable

ENV CELL_RUBY_VERSION 2.2.4

RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm && rvm requirements && rvm install $CELL_RUBY_VERSION && \
										 rvm alias create default $CELL_RUBY_VERSION && rvm cleanup all && \
										 echo 'gem: --no-document' >> ~/.gemrc && \
										 gem install bundler --no-ri --no-rdoc"

ADD ruby_entry.sh /opt/ruby_entry.sh
RUN chmod u=rxw,g=rx,o=rx /opt/ruby_entry.sh

VOLUME ["/opt/ruby_run"]

ENTRYPOINT ["/opt/ruby_entry.sh"]

# TODO- Remove from sudoers cell user for security reasons
