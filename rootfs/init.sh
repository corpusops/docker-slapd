#!/usr/bin/env bash
set -e
SLAPD_SDEBUG=${SLAPD_SDEBUG-}
if [[ -n $SLAPD_SDEBUG ]];then set -x;fi

join_by() { local IFS="$1"; shift; echo "$*"; }
log() { echo "$@" >&2; }
vv() { log "$@"; "$@"; }
version_lte() { [  "$1" = "$(printf "$1\n$2" | sort -V | head -n1)" ]; }
version_lt() { [ "$1" = "$2" ] && return 1 || version_lte $1 $2; }
version_gte() { [  "$2" = "$(printf "$1\n$2" | sort -V | head -n1)" ]; }
version_gt() { [ "$1" = "$2" ] && return 1 || version_gte $1 $2; }

NO_LOG="${NO_LOG-}"
SLAPD_EXTRA_ARGS="${SLAPD_EXTRA_ARGS-}"
SLAPD_INIT="${SLAPD_INIT-1}"
SLAPD_FIXPERMS="${SLAPD_FIXPERMS-1}"
SLAPD_SCHEMAS="${SLAPD_SCHEMAS-}"
SLAPD_HAS_SSL=${SLAPD_HAS_SSL-}
SLAPD_CERTS_DIR=${SLAPD_CERTS_DIR:-/certs}
HAS_FILE_SLAPD_CONF=${HAS_FILE_SLAPD_CONF-}
HAS_FILE_SLAPD_REPL=${HAS_FILE_SLAPD_REPL-}
HAS_FILE_SLAPD_ACLS=${HAS_FILE_SLAPD_ACLS-}
SUPERVISORD_CONFIGS="${SUPERVISORD_CONFIGS:-"/etc/supervisor.d/cron /etc/supervisor.d/rsyslog /slapdconf/supervisor"}"

export SLAPD_VERSION=${SLAPD_VERSION:-$(dpkg-query --showformat='${Version}' --show slapd|sed -re "s/\+.*//g")}

test_conf_files_presence() {
    local t="" k=""
    for t in slapd.conf slapd.acls slapd.repl;do
        k=${t//./_}
        k=${k^^}
        if [ -e /etc/ldap/$t ];then eval "HAS_FILE_$k=1";fi
    done
    export HAS_FILE_SLAPD_ACLS HAS_FILE_SLAPD_REPL HAS_FILE_SLAPD_CONF
}

init() {
    if [[ -z "${SLAPD_INIT}" ]];then return;fi
    frep /slapdconf/rebootcron:/etc/cron.d/rebootcron --overwrite
    if [ -e /slapdconf/schemas/$SLAPD_SCHEMA_VERSION/ldif ];then
        rsync -av --delete \
            "/slapdconf/schemas/$SLAPD_SCHEMA_VERSION/ldif/" \
            "/etc/ldap/slapd.d/cn=config/cn=schema/"
    fi
    if [ -e /slapdconf/schemas/$SLAPD_SCHEMA_VERSION/schema ];then
        rsync -av --delete \
            "/slapdconf/schemas/$SLAPD_SCHEMA_VERSION/schema/" \
            /etc/ldap/schema/
    fi
    if [[ -z "$SLAPD_SCHEMAS" ]] ;then
        schemas=$(find /etc/ldap/schema -type f 2>/dev/null -name "*.schema" | grep -v README | sort -V)
        if [[ -n "$schemas" ]];then
            SLAPD_SCHEMAS="$(join_by "|" $schemas)"
        fi
    fi
    export SLAPD_SCHEMAS

    while read f;do
        d="/etc/ldap/$f"
        dd="$(dirname $d)"
        if [ ! -e "$dd" ];then mkdir -p "$dd";fi
        vv frep /slapdconf/$f:$d --overwrite
        test_conf_files_presence
    done < <( cd /slapdconf \
        && for i in slapd.acls slapd.repl slapd.conf;do \
            if [ -e $i ];then echo $i;fi; \
        done \
        && if [ -e slapd.d ];then \
            : find slapd* -type f | grep -v /cn=schema/ \
            && : find slapd* -type f | grep    /cn=schema/ \
            | grep $SLAPD_SCHEMA_VERSION; \
        fi; )

    for i in cert privkey chain;do
        for j in \
            "/etc/slapd.d/cn=config.ldif" \
            /etc/ldap/slapd.conf \
            ; do
        if [ -e "$j" ] && [ ! -e "$SLAPD_CERTS_DIR/${i}.pem" ];then
            sed -i -e "/${SLAPD_CERTS_DIR//\//\\/}\/${i}.pem/d" "$j"
        fi
        done
    done

    for j in \
            /etc/ldap/slapd.conf \
            "/etc/slapd.d/cn=config.ldif" \
        ; do
        if ( grep -q .pem  "$j" );then
            SLAPD_HAS_SSL=1
            break
        fi
    done

    DEFAULT_SLAPD_SERVICES="ldap:/// ldapi:///"
    if [[ -n $SLAPD_HAS_SSL ]];then
        DEFAULT_SLAPD_SERVICES="$DEFAULT_SLAPD_SERVICES ldaps:///"
    fi
    SLAPD_SERVICES="${SLAPD_SERVICES:-$DEFAULT_SLAPD_SERVICES}"
    DEFAULT_SLAPD_ARGS="-g openldap -u openldap -d ${SLAPD_LOGLEVEL-256}"
    if [[ -n $HAS_FILE_SLAPD_CONF ]];then
        DEFAULT_SLAPD_ARGS="$DEFAULT_SLAPD_ARGS -f /etc/ldap/slapd.conf"
    else
        DEFAULT_SLAPD_ARGS="$DEFAULT_SLAPD_ARGS -F /etc/ldap/slapd.d"
    fi
    SLAPD_ARGS="${SLAPD_ARGS:-$DEFAULT_SLAPD_ARGS}"
    export SLAPD_SCHEMAS
    export SLAPD_HAS_SSL SLAPD_SERVICES SLAPD_ARGS SLAPD_EXTRA_ARGS
    export SUPERVISORD_CONFIGS SLAPD_SERVICES
    if [[ -z $NO_LOG ]] && [ -e /etc/ldap/slapd.conf ];then
        echo "Using slapd.conf" >&2
        sed -re "s/rootpw .*/rootpw xxx/g" /etc/ldap/slapd.conf >&2
        echo "########################" >&2
    fi
}

fixperms() {
    if [[ -z "${SLAPD_FIXPERMS}" ]];then return;fi
    local g=""
    for i in /var/run/slapd /var/lib/ldap;do if [ ! -e "$i" ];then mkdir -p "$i";fi;done
    if (getent group openldap >/dev/null 2>&1);then g=":openldap";fi
    chown -Rf "openldap$g" \
        /etc/ldap/slapd* \
        /var/lib/ldap \
        /var/run/slapd
}

fixperms
init
fixperms

if [[ -n "$@" ]];then
    exec $@
else
    exec /bin/supervisord.sh
fi
# vim:set et sts=4 ts=4 tw=80:
