# $FreeBSD: stable/11/usr.bin/calendar/tests/regress.sh 263227 2014-03-16 08:04:06Z jmmv $

CALENDAR_FILE="-f ${SRCDIR}/calendar.calibrate"
CALENDAR_BIN="calendar"

CALENDAR="${CALENDAR_BIN} ${CALENDAR_FILE}"

REGRESSION_START($1)

echo 1..28

REGRESSION_TEST(`s1',`$CALENDAR -t 29.12.2006')
REGRESSION_TEST(`s2',`$CALENDAR -t 30.12.2006')
REGRESSION_TEST(`s3',`$CALENDAR -t 31.12.2006')
REGRESSION_TEST(`s4',`$CALENDAR -t 01.01.2007')

REGRESSION_TEST(`a1',`$CALENDAR -A 3 -t 28.12.2006')
REGRESSION_TEST(`a2',`$CALENDAR -A 3 -t 29.12.2006')
REGRESSION_TEST(`a3',`$CALENDAR -A 3 -t 30.12.2006')
REGRESSION_TEST(`a4',`$CALENDAR -A 3 -t 31.12.2006')
REGRESSION_TEST(`a5',`$CALENDAR -A 3 -t 01.01.2007')

REGRESSION_TEST(`b1',`$CALENDAR -B 3 -t 31.12.2006')
REGRESSION_TEST(`b2',`$CALENDAR -B 3 -t 01.01.2007')
REGRESSION_TEST(`b3',`$CALENDAR -B 3 -t 02.01.2007')
REGRESSION_TEST(`b4',`$CALENDAR -B 3 -t 03.01.2007')
REGRESSION_TEST(`b5',`$CALENDAR -B 3 -t 04.01.2007')

REGRESSION_TEST(`w0-1',`$CALENDAR -W 0 -t 28.12.2006')
REGRESSION_TEST(`w0-2',`$CALENDAR -W 0 -t 29.12.2006')
REGRESSION_TEST(`w0-3',`$CALENDAR -W 0 -t 30.12.2006')
REGRESSION_TEST(`w0-4',`$CALENDAR -W 0 -t 31.12.2006')
REGRESSION_TEST(`w0-5',`$CALENDAR -W 0 -t 01.01.2007')
REGRESSION_TEST(`w0-6',`$CALENDAR -W 0 -t 02.01.2007')
REGRESSION_TEST(`w0-7',`$CALENDAR -W 0 -t 03.01.2007')

REGRESSION_TEST(`wn-1',`$CALENDAR -W 0 -t 28.12.2006')
REGRESSION_TEST(`wn-2',`$CALENDAR -W 1 -t 28.12.2006')
REGRESSION_TEST(`wn-3',`$CALENDAR -W 2 -t 28.12.2006')
REGRESSION_TEST(`wn-4',`$CALENDAR -W 3 -t 28.12.2006')
REGRESSION_TEST(`wn-5',`$CALENDAR -W 4 -t 28.12.2006')
REGRESSION_TEST(`wn-6',`$CALENDAR -W 5 -t 28.12.2006')
REGRESSION_TEST(`wn-7',`$CALENDAR -W 6 -t 28.12.2006')

REGRESSION_END()
