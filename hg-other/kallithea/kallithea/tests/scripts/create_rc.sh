#!/bin/sh
psql -U postgres -h localhost -c 'drop database if exists kallithea;'
psql -U postgres -h localhost -c 'create database kallithea;'
paster setup-db rc.ini --force-yes --user=username --password=qweqwe --email=username@example.com --repos=/home/username/repos --no-public-access
API_KEY=`psql -R " " -A -U postgres -h localhost -c "select api_key from users where admin=TRUE" -d kallithea | awk '{print $2}'`
echo "run those after running server"
paster serve rc.ini --pid-file=rc.pid --daemon
sleep 3
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 create_user username:demo1 password:qweqwe email:demo1@example.com
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 create_user username:demo2 password:qweqwe email:demo2@example.com
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 create_user username:demo3 password:qweqwe email:demo3@example.com
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 create_user_group group_name:demo12
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 add_user_to_user_group usergroupid:demo12 userid:demo1
kallithea-api --apikey=$API_KEY --apihost=http://127.0.0.1:5001 add_user_to_user_group usergroupid:demo12 userid:demo2
echo "killing server"
kill `cat rc.pid`
rm rc.pid
