ARG BASE=corpusops/ubuntu:20.04
FROM $BASE
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq
RUN set -x \
    && apt-get install -qq \
    ldap-utils \
    ca-certificates \
    slapd \
    monitoring-plugins libio-socket-ssl-perl \
    python3-ldap \
    libdate-manip-perl libgetopt-complete-perl libnet-ldap-perl \
    && mkdir -p /etc/ldap /var/run/slapd/  /var/lib/ldap/ \
    && chown openldap /etc/ldap /var/run/slapd/  /var/lib/ldap/ \
    && apt-get clean && rm -rfv /var/lib/apt/lists/* /var/cache/apt/archives/*
ARG LTB_VERSION=origin/master
ENV LTB_VERSION=$LTB_VERSION
RUN git clone https://github.com/ltb-project/nagios-plugins.git && cd nagios-plugins && git reset --hard $LTB_VERSION
RUN find /etc/ldap/slapd.d -type f -delete
ADD ./rootfs/ /
ENTRYPOINT ["/init.sh"]
