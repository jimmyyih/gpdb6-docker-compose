FROM pivotaldata/gpdb6-centos7-build

COPY install-dependencies.sh /opt
COPY setup-gpadmin.sh /opt

RUN /opt/install-dependencies.sh
RUN /opt/setup-gpadmin.sh
