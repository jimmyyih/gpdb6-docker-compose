#! /bin/bash

# Compile GPDB
docker exec -it gpdb6-docker-compose_cdw_1 /gpdb-scripts/compile-gpdb.sh

# Install and prepare for GPDB
for host in cdw sdw1 sdw2; do
    docker exec -it gpdb6-docker-compose_${host}_1 /gpdb-scripts/install-and-prep-for-gpdb.sh
done

# Create the GPDB cluster
docker exec -it gpdb6-docker-compose_cdw_1 /gpdb-scripts/create-gpdb-cluster.sh
