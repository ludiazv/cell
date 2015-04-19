# Cell container with golang
FROM atlo/cell
MAINTAINER Luis Diaz <ldiaz@atloideas.com>

RUN wget –q -O - https://storage.googleapis.com/golang/go1.4.2.linux-amd64.tar.gz | tar xz -C /opt && \
	apt-get update -qy && apt-get install git -qy && apt-get autoclean && apt-get clean && \
	rm -rf /var/lib/apt/lists/*

ENV GOROOT /opt/go
ENV PATH $PATH:$GOROOT/bin
