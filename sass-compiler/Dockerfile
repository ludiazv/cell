FROM atlo/ruby2-alpine

VOLUME ["/opt/sass"]
COPY sass_entry.sh /opt/sass_entry.sh
RUN sudo gem install sass --no-ri --no-rdoc && sudo chown cell:cell /opt/sass_entry.sh && sudo chmod u=rxw,o=r,g=r /opt/sass_entry.sh

ENTRYPOINT ["/opt/sass_entry.sh"]
