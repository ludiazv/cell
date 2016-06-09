# Cell container with RMV and jruby + git
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Do an update for packages
RUN apt-get update -yq && apt-get install git sudo -yq && apt-get autoclean && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* && echo "cell  ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers

USER cell
# add keys and installs RVM
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \curl -sSL https://get.rvm.io | bash -s stable

ENV CELL_RUBY_VERSION jruby-9.1.2.0

RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm && rvm install $CELL_RUBY_VERSION && \
 										 rvm alias create default $CELL_RUBY_VERSION && rvm cleanup all && \
										 echo \"gem: --no-document\" >> ~/.gemrc && \
										 gem install bundler --no-ri --no-rdoc"

ADD ruby_entry.sh /opt/ruby_entry.sh
RUN sudo chown cell:cell /opt/ruby_entry.sh && sudo chmod u=rxw,g=rx,o=rx /opt/ruby_entry.sh

VOLUME ["/opt/ruby_run"]

ENTRYPOINT ["/opt/ruby_entry.sh"]
