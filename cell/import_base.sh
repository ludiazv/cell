#!/bin/bash
#gzip -dc debian_wheezy.tar.gz > debian_wheezy.tar
bzip2 -dk debian_wheezy.tar.bz2
docker load < debian_wheezy.tar
rm -f debian_wheezy.tar
#gzip -dc busybox.tar.gz > busybox.tar
bzip2 -dk busybox.tar.bz2
docker load < busybox.tar
rm -f busybox.tar
