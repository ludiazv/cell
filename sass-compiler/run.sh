#!/bin/sh
source /etc/environment
docker run --rm -t --name sass-compiler-run -v $(pwd)/sample:/opt/sass atlo/sass-compiler "$@"
