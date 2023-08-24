PATH=`pwd`:/command:/usr/local/bin:/usr/local/sbin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/X11R6/bin:/usr/ucb
export PATH

umask 022

die() {
    echo "$@"
    exit 1
}

catexe() {
    cat > $1
    chmod +x $1
}

filter_svstat() {
    sed -e 's/[0-9]* seconds/x seconds/' -e 's/pid [0-9]*/pid x/'
}

rm -rf rts-tmp || die "Could not clean up old rts-tmp"
mkdir rts-tmp || die "Could not create new rts-tmp"
cd rts-tmp || die "Could not change to rts-tmp"
mkdir test.sv || die "Could not create test.sv"
TOP=`pwd`
echo '--- envdir requires arguments'
envdir whatever; echo $?

echo '--- envdir complains if it cannot read directory'
ln -s env1 env1
envdir env1 echo yes; echo $?

echo '--- envdir complains if it cannot read file'
rm env1
mkdir env1
ln -s Message env1/Message
envdir env1 echo yes; echo $?

echo '--- envdir adds variables'
rm env1/Message
echo This is a test. This is only a test. > env1/Message
envdir env1 sh -c 'echo $Message'; echo $?

echo '--- envdir removes variables'
mkdir env2
touch env2/Message
envdir env1 envdir env2 sh -c 'echo $Message'; echo $?
# not tested:

# envuidgid sets GID
# setuidgid

echo '--- envuidgid insists on two arguments'
envuidgid; echo $?
envuidgid root; echo $?

echo '--- envuidgid sets UID=0 for root'
envuidgid root printenv UID; echo $?

echo '--- envuidgid complains if it cannot run program'
envuidgid root ./nonexistent; echo $?
echo '--- fghack insists on an argument'
fghack; echo $?

echo '--- fghack complains if it cannot run program'
fghack ./nonexistent; echo $?

echo '--- fghack runs a program'
fghack sh -c 'echo hi &'; echo $?
echo '--- match handles literal string'
matchtest one one
matchtest one ''
matchtest one on
matchtest one onf
matchtest one 'one*'
matchtest one onetwo

echo '--- match handles empty string'
matchtest '' ''
matchtest '' x

echo '--- match handles full-line wildcard'
matchtest '*' ''
matchtest '*' x
matchtest '*' '*'
matchtest '*' one

echo '--- match handles ending wildcard'
matchtest 'one*' one
matchtest 'one*' 'one*'
matchtest 'one*' onetwo
matchtest 'one*' ''
matchtest 'one*' x
matchtest 'one*' on
matchtest 'one*' onf

echo '--- match handles wildcard termination'
matchtest '* one' ' one'
matchtest '* one' 'x one'
matchtest '* one' '* one'
matchtest '* one' 'xy one'
matchtest '* one' 'one'
matchtest '* one' ' two'
matchtest '* one' '  one'
matchtest '* one' 'xy one '

echo '--- match handles multiple wildcards'
matchtest '* * one' '  one'
matchtest '* * one' 'x  one'
matchtest '* * one' ' y one'
matchtest '* * one' 'x y one'
matchtest '* * one' 'one'
matchtest '* * one' ' one'
matchtest '* * one' '   one'

echo '--- fnmatch handles literal string'
matchtest Fone one
matchtest Fone ''
matchtest Fone on
matchtest Fone onf
matchtest Fone 'one*'
matchtest Fone onetwo

echo '--- fnmatch handles empty string'
matchtest 'F' ''
matchtest 'F' x

echo '--- fnmatch handles full-line wildcard'
matchtest 'F*' ''
matchtest 'F*' x
matchtest 'F*' '*'
matchtest 'F*' one

echo '--- fnmatch handles ending wildcard'
matchtest 'Fone*' one
matchtest 'Fone*' 'one*'
matchtest 'Fone*' onetwo
matchtest 'Fone*' ''
matchtest 'Fone*' x
matchtest 'Fone*' on
matchtest 'Fone*' onf

echo '--- fnmatch handles wildcard termination'
matchtest 'F* one' ' one'
matchtest 'F* one' 'x one'
matchtest 'F* one' '* one'
matchtest 'F* one' 'xy one'
matchtest 'F* one' 'one'
matchtest 'F* one' ' two'
matchtest 'F* one' '  one'
matchtest 'F* one' 'xy one '

echo '--- fnmatch handles multiple wildcards'
matchtest 'F* * one' '  one'
matchtest 'F* * one' 'x  one'
matchtest 'F* * one' ' y one'
matchtest 'F* * one' 'x y one'
matchtest 'F* * one' 'one'
matchtest 'F* * one' ' one'
matchtest 'F* * one' '   one'
# not tested:

# multilog handles TERM
# multilog handles ALRM
# multilog handles out-of-memory
# multilog handles log directories
# multilog matches only first 1000 characters of long lines
# multilog t produces the right time
# multilog closes descriptors properly

echo '--- multilog prints nothing with no actions'
( echo one; echo two ) | multilog; echo $?

echo '--- multilog e prints to stderr'
( echo one; echo two ) | multilog e 2>&1; echo $?

echo '--- multilog inserts newline after partial final line'
( echo one; echo two | tr -d '\012' ) | multilog e 2>&1; echo $?

echo '--- multilog handles multiple actions'
( echo one; echo two ) | multilog e e 2>&1; echo $?

echo '--- multilog handles wildcard -'
( echo one; echo two ) | multilog '-*' e 2>&1; echo $?

echo '--- multilog handles literal +'
( echo one; echo two ) | multilog '-*' '+one' e 2>&1; echo $?

echo '--- multilog handles fnmatch -'
( echo one; echo two ) | multilog F '-*' e 2>&1; echo $?

echo '--- multilog handles fnmatch +'
( echo one; echo two; echo one two ) | multilog F '-*' '+*o*' e 2>&1; echo $?

echo '--- multilog handles long lines for stderr'
echo 0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678 \
| multilog e 2>&1; echo $?
echo 01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789 \
| multilog e 2>&1; echo $?
echo 012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890 \
| multilog e 2>&1; echo $?

echo '--- multilog handles status files'
rm -f test.status
( echo one; echo two ) | multilog =test.status; echo $?
uniq -c < test.status | sed 's/[ 	]*[ 	]/_/g'

echo '--- multilog t has the right format'
( echo ONE; echo TWO ) | multilog t e 2>&1 | sed 's/[0-9a-f]/x/g'
echo '--- svstat handles new and nonexistent directories'
( echo '#!/bin/sh'; echo echo hi ) > test.sv/run
chmod 755 test.sv/run
touch test.sv/down
svstat test.sv nonexistent; echo $?

echo '--- svc handles new and nonexistent directories'
svc test.sv nonexistent; echo $?

echo '--- svok handles new and nonexistent directories'
svok test.sv; echo $?
svok nonexistent; echo $?

echo '--- supervise handles nonexistent directories'
supervise nonexistent; echo $?
# not tested:

# pgrphack works properly

echo '--- pgrphack insists on an argument'
pgrphack; echo $?

echo '--- pgrphack complains if it cannot run program'
pgrphack ./nonexistent; echo $?

echo '--- pgrphack runs a program'
pgrphack echo ok; echo $?
# not tested:

# readproctitle works properly

echo '--- readproctitle insists on an argument'
readproctitle < /dev/null; echo $?

echo '--- readproctitle insists on last argument being at least five bytes'
readproctitle .......... four < /dev/null; echo $?
echo '--- setlock requires arguments'
setlock whatever; echo $?

echo '--- setlock complains if it cannot create lock file'
setlock nonexistent/lock echo wrong; echo $?

echo '--- setlock -x exits quietly if it cannot create lock file'
setlock -x nonexistent/lock echo wrong; echo $?

echo '--- setlock creates lock file'
setlock lock echo ok; echo $?

echo '--- setlock does not truncate lock file'
echo ok > lock
setlock lock cat lock; echo $?
rm -f lock

echo '--- setlock -n complains if file is already locked'
setlock lock sh -c 'setlock -n lock echo one && echo two'; echo $?

echo '--- setlock -nx exits quietly if file is already locked'
setlock lock sh -c 'setlock -nx lock echo one && echo two'; echo $?
# not tested:

# softlimit -m
# softlimit -d
# softlimit -s
# softlimit -l
# softlimit -a
# softlimit -p0 preventing fork; need to run this as non-root
# softlimit -o; shared libraries make tests difficult here
# softlimit -c
# softlimit -f
# softlimit -r
# softlimit -t
# softlimit reading env

echo '--- softlimit insists on an argument'
softlimit; echo $?

echo '--- softlimit complains if it cannot run program'
softlimit ./nonexistent; echo $?

echo '--- softlimit -p0 still allows exec'
softlimit -p0 echo ./nonexistent; echo $?
# not tested:

# supervise closes descriptors properly
# svc -p
# svscanboot

echo '--- supervise starts, svok works, svup works, svstat works, svc -x works'
supervise test.sv &
until svok test.sv
do
  sleep 1
done
svup test.sv; echo $?
svup -l test.sv; echo $?
svup -L test.sv; echo $?
( svstat test.sv; echo $?; ) | filter_svstat
svc -x test.sv; echo $?
wait
svstat test.sv; echo $?

echo '--- svc -ox works'
supervise test.sv &
until svok test.sv
do
  sleep 1
done
svc -ox test.sv
wait

echo '--- svstat and svup work for up services'
catexe test.sv/run <<EOF
#!/bin/sh
sleep 1
svstat .
echo $?
svstat -l .
echo $?
svstat -L .
echo $?
svup .
echo \$?
svup -L .
echo \$?
svup -l .
echo \$?
EOF
supervise test.sv | filter_svstat &
until svok test.sv
do
  sleep 1
done
svc -ox test.sv
wait

echo '--- svstat and svup work for logged services'
catexe test.sv/run <<EOF
#!/bin/sh
sleep 1
svstat .
echo $?
svstat -l .
echo $?
svstat -L .
echo $?
svup .
echo \$?
svup -L .
echo \$?
svup -l .
echo \$?
EOF
catexe test.sv/log <<EOF
#!/bin/sh
exec cat
EOF
supervise test.sv | filter_svstat &
until svok test.sv
do
  sleep 1
done
svc -Lolox test.sv
wait
rm -f test.sv/log

echo '--- svc -u works'
( echo '#!/bin/sh'; echo echo first; echo mv run2 run ) > test.sv/run
chmod 755 test.sv/run
( echo '#!/bin/sh'; echo echo second; echo svc -x . ) > test.sv/run2
chmod 755 test.sv/run2
supervise test.sv &
until svok test.sv
do
  sleep 1
done
svc -u test.sv
wait
echo '--- supervise runs stop on down'
( echo '#!/bin/sh'; echo svc -dx . ) >test.sv/run
( echo '#!/bin/sh'; echo echo in stop ) >test.sv/stop
rm -f test.sv/down
chmod +x test.sv/run test.sv/stop
supervise test.sv &
wait
rm -f test.sv/stop
echo

echo '--- supervise stops log after main'
( echo '#!/bin/sh'; echo 'exec ../../sleeper' ) >test.sv/log
chmod +x test.sv/log
supervise test.sv
wait
rm -f test.sv/log
echo
( echo '#!/bin/sh'; echo 'exec ../../sleeper' ) > test.sv/run
chmod 755 test.sv/run

echo '--- svc sends right signals'
supervise test.sv &
sleep 1
svc -a test.sv
sleep 1
svc -c test.sv
sleep 1
svc -h test.sv
sleep 1
svc -i test.sv
sleep 1
svc -t test.sv
sleep 1
svc -q test.sv
sleep 1
svc -1 test.sv
sleep 1
svc -2 test.sv
sleep 1
svc -w test.sv
sleep 1
svc -d test.sv
sleep 1
svc -xk test.sv
wait
# set up services
mkdir service svc0 svc1 svc2 svc2/log

catexe svc0/run <<EOF
#!/bin/sh
echo svc0 ran >> output
EOF

catexe svc1/run <<EOF
#!/bin/sh
echo svc1 ran
EOF

catexe svc1/log <<EOF
#!/bin/sh
cat > output
EOF

catexe svc2/run <<EOF
#!/bin/sh
echo svc2 ran
EOF

catexe svc2/log/run <<EOF
#!/bin/sh
cat > ../output
EOF

ln -s `pwd`/svc[0-9] service/

svscan `pwd`/service >svscan.log 2>&1 &
svscanpid=$!

until svok svc0 && svok svc1 && svok svc2 && svok svc2/log
do
  sleep 1
done

# stop svscan and clean up
kill $svscanpid
wait >/dev/null 2>&1

svc -dx svc[0-9] svc2/log
until ! svok svc0 && ! svok svc1 && ! svok svc2 && ! svok svc2/log
do
  sleep 1
done

head -n 1 svc[0-9]/output
cat svscan.log
rm -r svc0 svc1 svc2 service
# not tested:

# tai64n produces the right time
# tai64nlocal converts times correctly

echo '--- tai64n has the right format'
( echo ONE; echo TWO ) | tai64n | sed 's/[0-9a-f]/x/g'

echo '--- tai64nlocal handles non-@ lines correctly'
( echo one; echo two ) | tai64nlocal; echo $?
cd ..
rm -rf rts-tmp
