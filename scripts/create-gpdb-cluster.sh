#! /bin/bash

# Create data directories
mkdir -p /data/qddir && chown -R gpadmin:gpadmin /data/qddir
ssh sdw1 "mkdir -p /data/primary /data/mirror && chown -R gpadmin:gpadmin /data/primary /data/mirror"
ssh sdw2 "mkdir -p /data/primary /data/mirror && chown -R gpadmin:gpadmin /data/primary /data/mirror"

# Run gpinitsystem as gpadmin user
su gpadmin -c "
   # Run gpinitsystem
   cd /gpdb-scripts
   source /usr/local/gpdb/greenplum_path.sh
   gpinitsystem -a -c configs/clusterConfigFile -p configs/clusterConfigPostgresAddonsFile -h configs/hostfile
"

# Create environment file
cat > ~gpadmin/env.sh <<EOF
#! /bin/bash

source /usr/local/gpdb/greenplum_path.sh
export MASTER_DATA_DIRECTORY=/data/qddir/gpseg-1
export PGPORT=7000

EOF
