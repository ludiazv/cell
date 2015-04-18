# Container for basic local storage docker registry
FROM registry
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

RUN mkdir -p /opt/registry-data 
ADD registry_conf.yml /docker-registry/config/registry_conf.yml

ENV DOCKER_REGISTRY_CONFIG /docker-registry/config/registry_conf.yml
ENV SETTINGS_FLAVOR prod

CMD ["docker-registry"]



