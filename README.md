# GPDB 6 Docker Compose

This is a docker compose repository to build and orchestrate a GPDB 6X
multinode cluster for dev testing. This can be useful when there is a
need to have multiple hosts and the single-node gpdemo cluster is
insufficient. The docker compose GPDB 6 cluster is ephemeral so the
cluster can be discarded and rebuilt for quick and clean testing. The
OS of choice here is CentOS 7.

## Build the image

We need to build a local docker image that will be used for each
container in the multinode cluster. The image here is specifically
designed to work for GPDB 6 compilation and running the cluster.

```
pushd ./build/
docker build -t gpdb6-multinode-cluster/gpdb-image .
popd
```

Note: You only have to build the image once (unless there is an update
to the build directory). The image is stored locally.

## Set environment variables

The `docker-compose.yaml` uses two environment variables:
1. `$GPDB6_SRC` (the path to your GPDB 6X source code)
```
Example:
export GPDB6_SRC=/Users/jyih/workspace/gpdb6
```
Note: The `$GPDB6_SRC` path will be mounted and used for compilation
so it would be good to run `git clean -xfd` in the directory to rid of
anything (e.g. MacOS compiled binaries).

2. `$PWD` (the path to the top-level dir of this repository)
Note: You have to run `docker-compose` in the top-level dir anyways so
`$PWD` should always be correct.

## Run docker compose

This step will create the GPDB hosts (3 containers), build a network
bridge between the 3 containers, and mount a shared volume (the GPDB 6
source code and some orchestration scripts from this repository).

```
# In this repository's top-level dir
docker-compose up -d
```

## Run coordinate-everything.sh script

This step will install the compiled GPDB 6 onto each host and run
gpinitsystem to create the GPDB 6X cluster.

```
pushd ./scripts/
bash coordinate-everything.sh
popd
```

Afterwards, you'll be able to connect to the coordinator node and
start your testing.

```
docker exec -it gpdb6-docker-compose_cdw_1 /bin/bash
su - gpadmin
source env.sh
```

## Stop and delete everything

This step will destroy everything we've created. Run this when you no
longer need the cluster.

```
# In this repository's top-level dir
docker-compose down -v
```
