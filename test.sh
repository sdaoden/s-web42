#!/bin/sh -
#@ S-Web42 unit test

trap "rm -rf test-*" 0 1 2 15

errs=0
terr() {
	echo >&2 "FAILED: ${1}: mismatch(es) in ${2}"
	errs=`expr ${errs} + 1`
}

tcase() {
	tno=`expr "${1}-" : '\(.*\)-w42.*'`
	echo "${2}" > test-${1}
	[ -n "${3}" ] && echo "${3}" > test-eout || :> test-eout
	[ -n "${4}" ] && echo "${4}" > test-eerr || :> test-eerr
	./s-web42 --no-rc --eo test-${1} > test-out 2> test-err
	cmp -s test-out test-eout
	[ $? -ne 0 ] && o='STDOUT ' || o=
	cmp -s test-err test-eerr
	[ $? -ne 0 ] && e='STDERR ' || e=
	[ -z "${o}${e}" ] && echo "OK: ${tno}" || terr ${tno} "${o}${e}"
}

##

# def/defa/defx
tcase 0001-w42-atm \
'<?begin?>

<?def def1<><p>def1-content</p>?>
<?defa defa1<><p>defa1-c1<>defa1-c2</p>?>
<?defx defx1<><p>defx1-c1</p><><p>defx1-c2</p><><p>defx1-c3</p>?>

<?def1?>
<?defa1 0?>
<?defa1 1?>
<?defx1 defx1-arg1<>defx1-arg2?>
# ERROR
<?defa1 2?>
# ERROR
<?defx1 defx1-arg1<>defx1-arg2<>defx1-arg3?>

<?def def2<>def2-content?>
<?defa defa2<>defa2-c1<>defa2-c2<>defa2-c3?>
<?defx defx2<><p>defx2-c1<>defx2-c2<>defx2-c3</p><>?>

<?def2?>
<?defa2 0?>
<?defa2 1?>
<?defa2 loop<>-<><br>?>
<?defx2 defx2-arg1<>defx2-arg2<>defx2-arg3?>

<?defa arrnam<>m 1?>
<?defa arrnam<>m 2?>
<?defa arrnam<>m 3<>m 4?>

<p><?arrnam 0?><?arrnam 1?>\
         <?arrnam 2?><?arrnam 3?></p>

<p><?arrnam loop<><b><></b>?></p>
<p><?arrnam loop<><><br>?></p>

<?end?>' \
\
'<p>def1-content</p>
<p>defa1-c1
defa1-c2</p>
<p>defx1-c1</p>defx1-arg1<p>defx1-c2</p>defx1-arg2<p>defx1-c3</p>
def2-content
defa2-c1
defa2-c2
-defa2-c1<br>-defa2-c2<br>-defa2-c3<br>
<p>defx2-c1defx2-arg1defx2-c2defx2-arg2defx2-c3</p>defx2-arg3
<p>m 1m 2m 3m 4</p>
<p><b>m 1</b><b>m 2</b><b>m 3</b><b>m 4</b></p>
<p>m 1<br>m 2<br>m 3<br>m 4<br></p>' \
\
"ERR 'test-0001-w42-atm':12: defa1: 2 is not a valid array index
ERR 'test-0001-w42-atm':14: defx1 takes 2 argument(s)"

##

# pi-if
tcase 0002-w42-atm \
'<?begin?>

<?def def1<><p>def1-content</p>?>
<?defx defx1<><p>defx1-c1 <> defx1-c2 <></p>?>

<?pi-if def1?>
<?pi-if defx1<>defx1-arg1<>defx1-arg2?>

# ERROR (silent)
<?pi-if def2?>
# ERROR (silent)
<?pi-if defx2<>defx2-arg2<>defx2-arg2?>

<?end?>' \
\
'<p>def1-content</p>
<p>defx1-c1 defx1-arg1 defx1-c2 defx1-arg2</p>' \
\
''

##

# undef
tcase 0003-w42-atm \
'<?begin?>

<?def def1<><p>def1-content</p>?>
<?defx defx1<><p>defx1-c1 <> defx1-c2 <></p>?>

<?undef def1?>
<?undef defx1?>

# ERROR
<?undef?>
# ERROR
<?undef undef?>
# ERROR
<?undef def2?>
# ERROR
<?undef defx2?>

<?end?>' \
\
'' \
\
"ERR 'test-0003-w42-atm':10: undef takes 1 argument(s)
ERR 'test-0003-w42-atm':12: undef: cannot undef builtin PI (variable): undef
ERR 'test-0003-w42-atm':14: undef: no such variable: def2
ERR 'test-0003-w42-atm':16: undef: no such variable: defx2"

##

# lref,lreft, href,hreft
tcase 0004-w42-atm \
'<?begin?>

<?lref http://www.netbsd.org?>
<?lreft http://www.netbsd.org<><em>NetBSD</em>?>

<?href http://www.freebsd.org?>
<?hreft http://www.freebsd.org<>FreeBSD?>

<?def WWW<><strong>WWW!</strong>?>
<?href http://www.freebsd.org?>
<?hreft http://www.freebsd.org<>FreeBSD?>

<?def WWW<>"au"?>
<?href nope?>
<?hreft nope<><em title="SUB">FreeBSD</em>?>

## ERROR
<?lref a<>b?>
<?lreft a<>b<>c?>
<?href a<>b?>
<?hreft a<>b<>c?>

<?end?>' \
\
'<a href="http://www.netbsd.org">http://www.netbsd.org</a>
<a href="http://www.netbsd.org" title="NetBSD"><em>NetBSD</em></a>
<a href="http://www.freebsd.org">http://www.freebsd.org</a>
<a href="http://www.freebsd.org" title="FreeBSD">FreeBSD</a>
<a href="http://www.freebsd.org"><strong>WWW!</strong>&nbsp;http://www.freebsd.org</a>
<a href="http://www.freebsd.org" title="FreeBSD"><strong>WWW!</strong>&nbsp;FreeBSD</a>
<a href="nope">"au"&nbsp;nope</a>
<a href="nope" title="FreeBSD">"au"&nbsp;<em title="SUB">FreeBSD</em></a>' \
\
"ERR 'test-0004-w42-atm':18: lref takes 1 argument(s)
ERR 'test-0004-w42-atm':19: lreft takes 2 argument(s)
ERR 'test-0004-w42-atm':20: href takes 1 argument(s)
ERR 'test-0004-w42-atm':21: hreft takes 2 argument(s)"

##

[ ${errs} -eq 0 ] && exit 0 || exit 42
