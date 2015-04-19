# Cell container with golang
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

RUN wget –q -O - https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xz -C /opt

ENV GOROOT /opt/go
ENV PATH $PATH:$GOROOT/bin