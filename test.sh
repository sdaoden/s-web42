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
	./s-web42 --no-rc --eo test-${1} > test-${tno}-out 2> test-${tno}-err
	cmp -s test-${tno}-out test-eout
	[ $? -ne 0 ] && o='STDOUT ' || o=
	cmp -s test-${tno}-err test-eerr
	[ $? -ne 0 ] && e='STDERR ' || e=
	[ -z "${o}${e}" ] && echo "OK: ${tno}" || terr ${tno} "${o}${e}"
}

## Assignment test series {{{

# Variable
tcase 1000-w42-atm \
'X = one
<?begin?>
<?X?>
<?end?>' \
\
'one' \
\
''

tcase 1001-w42-atm \
'X = <em>two</em>
<?begin?>
<?X?>
<?end?>' \
\
'<em>two</em>' \
\
''

tcase 1002-w42-atm \
'X = <?def Y<>three?><?Y?><?undef Y?>
<?begin?>
<?X?>
<?end?>' \
\
'three' \
\
''

tcase 1003-w42-atm \
'X = <?def Y<><em>four</em>?><?Y?><?undef Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>four</em>' \
\
''

tcase 1004-w42-atm \
'X = <?def Y<><em>five</em>?><?Y?><?undef Y?><?Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>five</em>' \
\
"ERROR 'test-1004-w42-atm':3: Unknown PI: Y"

tcase 1005-w42-atm \
'X = <?def Y<><em>six</em>?>
X += <?Y?>
X += <?undef Y?>
X += <?Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>six</em>' \
\
"ERROR 'test-1005-w42-atm':6: Unknown PI: Y"

tcase 1006-w42-atm \
'X = <?def Y<><em>seven</em>?>
X ?= <?def Y<><em>NOOHNOOHNO</em>?>
X += <?Y?>
X ?= <?Y?>
X += <?undef Y?>
X += <?Y?>
Z ?= virgin
Z ?= bob
<?begin?>
<?X?>
<?Z?>
<?end?>' \
\
'<em>seven</em>
virgin' \
\
"ERROR 'test-1006-w42-atm':10: Unknown PI: Y"

# Array
tcase 2000-w42-atm \
'X @= one
<?begin?>
<?X 0?>
<?end?>' \
\
'one' \
\
''

tcase 2001-w42-atm \
'X @= one
X @= <em>two</em>
<?begin?>
<?X 0?><?X 1?>
<?end?>' \
\
'one<em>two</em>' \
\
''

tcase 2002-w42-atm \
'X @= one
X @= two
X @= three
<?begin?>
<?X loop?>
<?end?>' \
\
'onetwothree' \
\
''

tcase 2003-w42-atm \
'X @= one
X @= two
X @= three
X @= four
<?begin?>
<?X loop<> ?>
<?end?>' \
\
' one two three four' \
\
''

tcase 2004-w42-atm \
'X @= one
X @= two
X @= three
X @= four
<?begin?>
<?X loop<><> ?>
<?end?>' \
\
'one two three four ' \
\
''

tcase 2005-w42-atm \
'X @= one
X @= two
X @= three
X @= four
X @= five
<?begin?>
<?X loop<><em><></em>?>
<?end?>' \
\
'<em>one</em><em>two</em><em>three</em><em>four</em><em>five</em>' \
\
''

tcase 2006-w42-atm \
'X @= <?def Y<>a?><?Y?><?Y?><?Y?><?undef Y?>
X ?@= <?def Y<>z?><?Y?><?Y?><?Y?><?undef Y?>
X @= <?lref http://www.netbsd.org?>
Z ?@= virgin
Z ?@= bob
Z @= femme
<?begin?>
<?X 0?><?X 1?>
<?X loop<><p><></p>?>
<?Z loop<> <> ?>
<?end?>' \
\
'aaa<a href="http://www.netbsd.org">http://www.netbsd.org</a>
<p>aaa</p><p><a href="http://www.netbsd.org">http://www.netbsd.org</a></p>
 virgin  femme ' \
\
''

## }}}
## def/defa/defx {{{

tcase 0001-w42-atm \
'<?begin?>

<?def def1<><p>def1-cont<>ent</p>?>
<?defa defa1<><p>defa1-c1<>defa1-c2</p>?>
<?defx defx1<><p>defx1-c1</p><><p>defx1-c2</p><><p>defx1-c3</p>?>

<?def1?>
<?defa1 0?>
<?defa1 1?>
<?defx1 defx1-arg1<>defx1-arg2?>

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

<?defx defxx<><><>TRAIL?>
<p><?defxx ARG1<>arg2?></p>

REE<?def reeval1<><^def reeval2<>reeval-output-ok^><^reeval2^><^undef reeval2^>?><?reeval1?><?pi-if reeval2?>VAL

# ERROR(S)
<?def error?>
<?defa error?>
<?defx error?>
<?defa1 2?>
<?defx1 defx1-arg1<>defx1-arg2<>defx1-arg3?>
<?end?>' \
\
'<p>def1-cont<>ent</p>
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
<p>m 1<br>m 2<br>m 3<br>m 4<br></p>
<p>ARG1arg2TRAIL</p>
REEreeval-output-okVAL' \
\
"ERROR 'test-0001-w42-atm':38: def (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atm':39: defa (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atm':40: defx (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atm':41: defa1: 2 is not a valid array index
ERROR 'test-0001-w42-atm':42: defx1 takes 2 argument(s)"

## }}}
## pi-if {{{

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

## }}}
## undef {{{

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
"ERROR 'test-0003-w42-atm':10: undef takes 1 argument(s)
ERROR 'test-0003-w42-atm':12: undef: cannot undef builtin PI (variable): undef
ERROR 'test-0003-w42-atm':14: undef: no such variable: def2
ERROR 'test-0003-w42-atm':16: undef: no such variable: defx2"

## }}}
## lref,lreft, href,hreft {{{

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
"ERROR 'test-0004-w42-atm':18: lref takes 1 argument(s)
ERROR 'test-0004-w42-atm':19: lreft takes 2 argument(s)
ERROR 'test-0004-w42-atm':20: href takes 1 argument(s)
ERROR 'test-0004-w42-atm':21: hreft takes 2 argument(s)"

## }}}
## ?ifdef?.. {{{

tcase 0005-w42-atm \
'<?begin?>

<?ifdef 0?>
no.1
<?fi?>
<?ifdef 0?>
no.2
<?else?>
yes.1
<?fi?>
<?ifndef 0?>
yes.2
<?fi?>
<?ifndef 0?>
yes.3
<?else?>
no.3
<?fi?>

<?ifdef xYz?>
no.4
<?fi?>
<?ifdef xYz?>
no.5
<?else?>
yes.4
<?fi?>
<?ifndef xYz?>
yes.5
<?fi?>
<?ifndef xYz?>
yes.6
<?else?>
no.6
<?fi?>

<?def xYz<>it is defined now?>
<?ifdef xYz?>
yes.7
<?fi?>
<?ifdef xYz?>
yes.8
<?else?>
no.7
<?fi?>
<?ifndef xYz?>
no.8
<?fi?>
<?ifndef xYz?>
no.9
<?else?>
yes.9
<?fi?>

<?ifdef 0?>
no.10
 <?ifndef 0?>
no.11
  <?ifndef xYz?>
no.12
  <?else?>
no.13
  <?fi?>
no.14
 <?else?>
no.15
 <?fi?>
no.16
<?else?>
yes.10
<?fi?>

<?ifndef 0?>
yes.11
 <?ifdef 0?>
no.17
  <?ifdef xYz?>
no.18
   <?ifdef xYz?>
no.19
   <?else?>
no.20
   <?fi?>
no.21
  <?else?>
no.22
  <?fi?>
no.23
 <?else?>
yes.12
 <?fi?>
yes.13
<?else?>
no.24
<?fi?>

<?ifdef 0?>1<?else?>2<?fi?><?ifndef 0?>3<?else?>4<?fi?><?ifndef 0?>5<?ifdef 0?>6<?else?>7<?fi?>8<?else?>9<?fi?>:)

<?ifdef 0?>
 <?NON-EXISTENT-PI?>
 <?ifdef 0?>
 <?else?>

<?end?>' \
\
'yes.1
yes.2
yes.3
yes.4
yes.5
yes.6
yes.7
yes.8
yes.9
yes.10
yes.11
yes.12
yes.13
23578:)' \
\
"ERROR 'test-0005-w42-atm':104: ifn?def: was started here, but where's the <?fi?>?
ERROR 'test-0005-w42-atm':104: ifn?def: was started here, but where's the <?fi?>?"

## }}}
## ?include?.. {{{

printf "<?begin?>\n1.1\n<?include test-0006-2?>\n1.2\n<?end?>" > test-0006-1
printf "<?begin?>\n2.1\n<?include test-0006-3?>\n2.2\n<?end?>" > test-0006-2
printf "<?begin?>\n3\n<?end?>" > test-0006-3
tcase 0006-w42-atm \
'<?begin?>
<?include test-0006-1?>
<?end?>' \
\
'1.1
2.1
3
2.2
1.2' \
\
''

# }}}

[ ${errs} -eq 0 ] && exit 0 || exit 42
