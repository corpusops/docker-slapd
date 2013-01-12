#!/usr/bin/env bash
cd $(dirname $0)
WARNING=${WARNING:-240}
CRITICAL=${CRITICAL:-600}
HOST=${HOST:-"ldap://127.0.0.1"}
perl /nagios-plugins/check_ldap_syncrepl_status.pl \
    -f \
    -H "$HOST" \
    -w "$WARNING" \
    -c "$CRITICAL" \
    -D "$SLAPD_ROOT_DN" \
    -P "$SLAPD_ROOT_PASSWORD" \
    -U "$(echo $SLAPD_SYNCREPL|base64 -d|xargs -n1|grep -E ^provider=|sed -re "s/provider=//g")"
# vim:set et sts=4 ts=4 tw=80:
