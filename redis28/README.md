

Usage:
docker run -i -e HOST_IP=${COREOS_PRIVATE_IPV4} -p ${COREOS_PRIVATE_IPV4}:6379:6370 --rm --privileged --name redis -t atlo/redis28