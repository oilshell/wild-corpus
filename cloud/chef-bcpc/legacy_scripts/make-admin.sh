#!/bin/bash
if [[ -z "$1" ]]; then
    HOST=$(hostname -f)
else
    HOST="$1"
fi
knife client show $HOST > /dev/null
RES=$?
if [[ "$RES" -ne 0 ]]; then
    echo "Can't find knife client $HOST"
    exit $RES
fi 
admin_val=`knife client show ${HOST} | grep ^admin: | sed "s/admin:[^a-z]*//"`
if [[ "$admin_val" != "true" ]]; then
    echo -e "/\"admin\": false\ns/false/true\nw\nq\n" | EDITOR=ed knife client edit ${HOST}
fi
