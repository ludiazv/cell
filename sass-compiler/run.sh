#!/bin/sh
source /etc/environment
docker run --rm -it --name sass-compiler-run -v $(pwd)/sample:/opt/sass atlo/sass-compiler "$@"
