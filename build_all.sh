#!/bin/bash
./remove_all.sh
#cd cell && ./import_base.sh && ./build.sh && cd ..
cd cell && ./build.sh && cd ..
cd jre7 && ./build.sh && cd ..
cd ruby2 && ./build.sh && cd ..
cd rails42 && ./build.sh && cd ..
#cd memcached && ./build.sh && cd ..
cd redis28 && ./build.sh && cd ..
cd psql94  && ./build.sh && cd ..
cd cassandra20 && ./build.sh && cd ..
cd eleasticsearch15 && ./build.sh && cd ..



