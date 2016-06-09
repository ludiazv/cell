#!/bin/bash
#./remove_all.sh
#cd cell && ./import_base.sh && ./build.sh && cd ..
# Base
cd cell && ./build.sh ; cd ..
cd registry && ./build.sh; cd ..

# Langs + Frameworks
cd golang14 && ./build.sh ; cd ..
#cd node && ./build.sh ; cd ..
cd ruby2 && ./build.sh ; cd ..
cd jruby9k && ./build.sh ; cd ..
cd jre7 && ./build.sh ; cd ..
cd rails42 && ./build.sh ; cd ..

# Caches + DBs
cd memcached && ./build.sh && cd ..
cd redis28 && ./build.sh ; cd ..
cd psql  && ./build.sh ; cd ..
cd mysql && ./build.sh ; cd ..
cd cassandra20 && ./build.sh ; cd ..
#cd eleasticsearch15 && ./build.sh ; cd ..

# Services
#cd nginx && ./build.sh ; cd ..

# Extras
cd etcd-yaml && ./build.sh ; cd ..

# Applications
#cd wordpress && ./build.sh ; cd ..
