ARG BASE=corpusops/ubuntu-bare:24.04
ARG RSYNC=corpusops/rsync
FROM $BASE AS final
ENV DEBIAN_FRONTEND=noninteractive
ADD apt.txt ./
RUN set -x \
    && DO_UPDATE="$DO_UPDATE" WANTED_EXTRA_PACKAGES="$(cat apt.txt)" cops_pkgmgr_install.sh\
    && mkdir -p /etc/ldap /var/run/slapd/  /var/lib/ldap/ \
    && chown openldap /etc/ldap /var/run/slapd/  /var/lib/ldap/ \
    && apt-get clean && rm -rfv /var/lib/apt/lists/* /var/cache/apt/archives/*
ARG LTB_VERSION=origin/master
ENV LTB_VERSION=$LTB_VERSION
RUN git clone https://github.com/ltb-project/nagios-plugins.git && cd nagios-plugins && git reset --hard $LTB_VERSION
RUN find /etc/ldap/slapd.d -type f -delete
ADD ./rootfs/ /

# SQUASH CODE
FROM $RSYNC AS squashed-rsync
FROM $BASE AS squashed-ancestor
ARG ROOTFS="/BASE_ROOTFS_TO_COPY_THAT_WONT_COLLIDE_1234567890"
ARG PATH="${ROOTFS}_rsync/bin:$PATH"
SHELL ["busybox",  "sh", "-c"]
RUN --mount=type=bind,from=final,target=$ROOTFS --mount=type=bind,from=squashed-rsync,target=${ROOTFS}_rsync \
rsync -Aaz --delete ${ROOTFS}/ / --exclude=/proc --exclude=/sys --exclude=/etc/resolv.conf --exclude=/etc/hosts --exclude=$ROOTFS* --exclude=dev/shm --exclude=dev/pts --exclude=dev/mqueue
SHELL ["/bin/sh", "-c"]
ENTRYPOINT ["/init.sh"]
