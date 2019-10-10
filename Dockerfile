FROM corpusops/ubuntu:18.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq
RUN apt-get install -qq \
    ldap-utils \
    ca-certificates \
    slapd \
    python-ldap
RUN find /etc/ldap/slapd.d -type f -delete
ADD ./rootfs/ /
ENTRYPOINT ["/init.sh"] 
