# Cell container with RMV and ruby2
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>
ENV DEBIAN_FRONTEND   noninteractive

# Do an update for packages
RUN apt-get update -yq && apt-get install sudo -yq && echo "cell  ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers
USER cell
# add keys and installs RVM 
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 && \curl -sSL https://get.rvm.io | bash -s stable

RUN /bin/bash -l -c "source ~/.rvm/scripts/rvm && rvm requirements && rvm install 2.2.1 && rvm alias create default 2.2.1 && gem update --system && echo "gem: --no-document" >> ~/.gemrc && gem install bundler --no-ri --no-rdoc"

ADD ruby_entry.sh /opt/ruby_entry.sh
RUN chmod u=rxw,g=rx,o=rx /opt/ruby_entry.sh

ENTRYPOINT ["/opt/ruby_entry.sh"]