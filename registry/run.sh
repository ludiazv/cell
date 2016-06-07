#!/bin/sh
source /etc/environment
#docker run -i --rm -t -p ${COREOS_PRIVATE_IPV4}:5000:5000 --name registro -v $(pwd)/test-data:/opt/registry-data atlo/registry
docker run -i -t --rm -p ${COREOS_PRIVATE_IPV4}:5000:5000 --name registro \
      -v $(pwd)/test-data:/opt/registry-data atlo/registry:2.0
