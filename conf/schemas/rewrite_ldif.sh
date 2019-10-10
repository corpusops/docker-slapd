#!/usr/bin/env bash
cd $(dirname $(readlink -f $0))
set -ex
rewrite_perl() {
    perl -0777 -p \
        -e 's/\n //g;' \
        -e 's/ (ORDERING|SINGLE-VALUE|NAME|AUXILIARY|SUBSTR|SUP|DESC|EQUALITY|SYNTAX|STRUCTURAL (MAY|MUST)) /\n \1 /g;' \
        -e 's/ (MAY|MUST)/\n \1 /g;' \
        -e 's/ (OBSOLETE)/\n \1/g;' \
        -e "s/ +\n/\n/g;" \
        -e "s/([0-9])\n NAME/\1 NAME/g;" \

}
for i in $@;do
    cd $i
    while read f;do
        s="schema/$(basename $f .ldif).schema"
        sed -r \
            -e "/^(#|(structuralObjectClass|dn|objectClass|cn|modifiersName|creatorsName|createTimestamp|modifyTimestamp|entryUUID|entryCSN): .*)/d" \
            -e "s/olcObjectClasses: \{[0-9]+\}/\nobjectclass /g" \
            -e "s/olcAttributeTypes: \{[0-9]+\}/\nattributetype /g" \
            -e "s/ NAME '([^']+)'/ NAME ( '\1' )/g" \
            $f \
            | rewrite_perl \
            > "$s"
    done < <(ls ldif/*ldif)
    cd -
done
# vim:set et sts=4 ts=4 tw=0:
