#!/bin/sh
cd /opt/sass
echo "$@"
sass --no-cache --scss --sourcemap=auto --quiet --style compressed "$@"
