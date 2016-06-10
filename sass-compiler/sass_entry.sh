#!/bin/sh
cd /opt/sass
sass --no-cache --scss --sourcemap=auto --quiet --style compressed "$@"
