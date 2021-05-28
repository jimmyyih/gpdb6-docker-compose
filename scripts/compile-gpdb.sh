#! /bin/bash

cd /gpdb-src
./configure --disable-orca --disable-gpcloud --with-libxml --with-python --with-perl --enable-mapreduce --enable-debug
make -j8
