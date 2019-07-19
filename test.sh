#!/bin/sh -
#@ S-Web42 unit test

trap "rm -rf ./test-*; exit" 0 1 2 15

errs=0
terr() {
	echo >&2 "FAILED: ${1} - ${2}: flaws in ${3}"
	errs=`expr ${errs} + 1`
}

WEB42=./s-web42
RC=--no-rc

rm_file() {
	# This does not work with Heirloom sh(1), even though the construct
	# works as such; this was reproducable as long as i was tired to find
	# the problem; let's just use printf(1) instead
	#: > "${1}"
	printf '' > "${1}"
}

tcase() {
	tno=`expr "${2}-" : '\(.*\)-w42.*'`
	[ -n "${3}" ] && printf "${3}" > ./test-${2}
	[ -n "${4}" ] && printf "${4}" > ./test-eout || rm_file ./test-eout
	[ -n "${5}" ] && printf "${5}" > ./test-eerr || rm_file ./test-eerr
	${WEB42} ${RC} --eo test-${2} > ./test-${tno}-out 2> ./test-${tno}-err
	cmp -s ./test-${tno}-out ./test-eout
	[ $? -ne 0 ] && o='OUT ' || o=
	cmp -s ./test-${tno}-err ./test-eerr
	[ $? -ne 0 ] && e='ERR ' || e=
	[ -z "${o}${e}" ] && echo "OK: ${tno} - ${1}" ||
		terr ${tno} "${1}" "${o}${e}"
}

## Basic filter test series (icewp) {{{

tcase 'Drop of trailing whitespace (cannot be disabled)' 842-w42-icewpatsm \
'H = H
<?begin?>
A

# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?>
<?end?>' \
\
'A

# SPACE
 B
# TAB
	C
# TAB SPACE
	 D
E\\
F \\
G
<?H?>
' \
\
''

tcase 'Drop of introductional whitespace (disable mode: i)' 843-w42-cewpatsm \
'H = H
<?begin?>A

# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?><?end?>' \
\
'A

# SPACE
B
# TAB
C
# TAB SPACE
D
E\\
F \\
G
<?H?>
' \
\
''
# FIXME wrong: explilicl NO TRAIL NL!

tcase 'Handling of shell style comments (disable mode: c)' 844-w42-ewpatsm \
'H = H
<?begin?>
A

# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?>
<?end?>' \
\
'A

B
C
D
E\\
F \\
G
<?H?>
' \
\
''

tcase 'Escaping of newlines (disable mode: e)' 845-w42-wpatsm \
'H = H
<?begin?>A

# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?><?end?>' \
\
'A

B
C
D
EF G
<?H?>
' \
\
''

tcase 'Wiping away empty lines (disable mode: w), 1' 846-w42-wpatsm \
'H = H
<?begin?>A

# SPACE
 B

# TAB

	C	
# TAB SPACE
	 D	                                        

E\\
F \\
G

<?H?>

<?end?>' \
\
'A

B


C
D

EF G

<?H?>

' \
\
''

tcase 'Wiping away empty lines (disable mode: w), 2' 847-w42-patsm \
'H = H
<?begin?>A

# SPACE
 B

# TAB

	C	
# TAB SPACE
	 D	                                        

E\\
F \\
G

<?H?>

<?end?>' \
\
'A
B
C
D
EF G
<?H?>
' \
\
''

tcase 'PI expansion (disable mode: p), 1' 848-w42-atsm \
'H = H
<?begin?>A
# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?><?end?>' \
\
'A
B
C
D
EF G
H' \
\
''

tcase 'PI expansion (disable mode: p), 2' 849-w42-atsm \
'H = H
<?begin?>
A
# SPACE
 B 
# TAB
	C	
# TAB SPACE
	 D	                                        
E\\
F \\
G
<?H?>
<?end?>' \
\
'A
B
C
D
EF G
H
' \
\
''

## }}}
## Assignments test series {{{

# Variable
tcase 'Assignments: variable, 1' 864-w42-atsm \
'X = one
Y =
z =    
<?begin?>
<?X?>a<?Y?>b<?z?>c
<?end?>' \
\
'oneabc
' \
\
''

tcase 'Assignments: variable, 2' 865-w42-atsm \
'X = <em>two</em>
<?begin?>
<?X?>
<?end?>' \
\
'<em>two</em>
' \
\
''

tcase 'Assignments: variable, 3' 866-w42-atsm \
'X = <?def Y<>three?><?Y?><?undef Y?>
<?begin?>
<?X?>
<?end?>' \
\
'three
' \
\
''

tcase 'Assignments: variable, 4' 867-w42-atsm \
'X = <?def Y<><em>four</em>?><?Y?><?undef Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>four</em>
' \
\
''

tcase 'Assignments: variable, 5' 868-w42-atsm \
'X = <?def Y<><em>five</em>?><?Y?><?undef Y?><?Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>five</em>
' \
\
"ERROR 'test-868-w42-atsm':3: Unknown PI: Y
"

tcase 'Assignments: variable, 6' 869-w42-atsm \
'X = <?def Y<><em>six</em>?>
X += <?Y?>
X += <?undef Y?>
X += <?Y?>
<?begin?>
<?X?>
<?end?>' \
\
'<em>six</em>
' \
\
"ERROR 'test-869-w42-atsm':6: Unknown PI: Y
"

tcase 'Assignments: variable, 7' 870-w42-atsm \
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
virgin
' \
\
"ERROR 'test-870-w42-atsm':10: Unknown PI: Y
"

# Array
tcase 'Assignments: array, 1' 884-w42-atsm \
'X @= one
<?begin?>
<?X 0?>
<?end?>' \
\
'one
' \
\
''

tcase 'Assignments: array, 2' 885-w42-atsm \
'X @= one
X @= <em>two</em>
<?begin?>
<?X 0?><?X 1?>
<?end?>' \
\
'one<em>two</em>
' \
\
''

tcase 'Assignments: array, 3' 886-w42-atsm \
'X @= one
X @= two
X @= three
<?begin?>
<?X loop?>
<?end?>' \
\
'onetwothree
' \
\
''

tcase 'Assignments: array, 4' 887-w42-atsm \
'X @= one
X @= two
X @= three
X @= four
<?begin?>
<?X loop<> ?>
<?end?>' \
\
' one two three four
' \
\
''

tcase 'Assignments: array, 5' 888-w42-atsm \
'X @= one
X @= two
X @= three
X @= four
<?begin?>
<?X loop<><> ?>
<?end?>' \
\
'one two three four 
' \
\
''

tcase 'Assignments: array, 6' 889-w42-atsm \
'X @= one
X @= two
X @= three
X @= four
X @= five
<?begin?>
<?X loop<><em><></em>?>
<?end?>' \
\
'<em>one</em><em>two</em><em>three</em><em>four</em><em>five</em>
' \
\
''

tcase 'Assignments: array, 7' 890-w42-atsm \
'X @= <?def Y<>a?><?Y?><?Y?><?Y?><?undef Y?>
X ?@= <?def Y<>z?><?Y?><?Y?><?Y?><?undef Y?>
X @= <?lref http://www.netbsd.org?>
Z ?@= virgin
Z ?@= bob
Z @= femme
BEEF = no
BEEF @= dead
<?begin?>
<?X 0?><?X 1?>
<?X loop<><p><></p>?>
<?Z loop<> <> ?>
<?end?>' \
\
'aaa<a href="http://www.netbsd.org">http://www.netbsd.org</a>
<p>aaa</p><p><a href="http://www.netbsd.org">http://www.netbsd.org</a></p>
 virgin  femme 
' \
\
"ERROR 'test-890-w42-atsm':8: BEEF: array assignment to non-array key
"

## }}}
## def/defa/defx {{{

tcase 'def/defa/defx' 0001-w42-atsm \
'<?begin?>

<?def def0<>?><?defa defa0<>?><?def def1<><p>def1-cont<>ent</p>?>
<?defa defa1<><p>defa1-c1<>defa1-c2</p>?>
<?defx defx1<><p>defx1-c1</p><><p>defx1-c2</p><><p>defx1-c3</p>?>

a<?def0?>b<?def0?>ca<?defa0?>b<?defa0?>c<?def1?>
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

<p><?arrnam 0?><?arrnam 1?>\\
         <?arrnam 2?><?arrnam 3?></p>

<p><?arrnam loop<><b><></b>?></p>
<p><?arrnam loop<><><br>?></p>

<?defx defxx<><><>TRAIL?>
<p><?defxx ARG1<>arg2?></p>

REE<?def reeval1<><^def reeval2<>reeval-output-ok^><^reeval2^><^undef reeval2^>?><?reeval1?><?pi-if reeval2?>VAL

<?tonga push<>entry 1?><?tonga unshift<>entry 0?><?tonga push<>entry 2?>
<?tonga loop<><> ?><br />
<?tonga pop?><?tonga shift?>
<?tonga loop<><> ?><br />
<?tonga pop?>
<?tonga loop<><> ?><br />
<?tonga undef-empty?><?ifdef tonga?>tonga should not be there<?fi?>

<?defx note<><em><></em>: <>.?>
<?defx subscription<><^note For subscribers only<^><>^>?>
<?subscription nonexistent list?>

# ERROR(S)
<?def error?>
<?defa error?>
<?defx error?>
<?defa1 2?>
<?defx1 defx1-arg1<>defx1-arg2<>defx1-arg3?>
<?MODTIME_SLOCAL push<>this is a variable and does not take arguments?>
<?MODTIME_ALOCAL push<>this is a builtin variable and cannot be modified?>
<?NOW_SLOCAL push<>this is a variable and does not take arguments?>
<?NOW_ALOCAL push<>this is a builtin variable and cannot be modified?>
<?end?>' \
\
'abcabc<p>def1-cont<>ent</p>
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
REEreeval-output-okVAL
entry 0 entry 1 entry 2 <br />
entry 1 <br />
<br />
<em>For subscribers only</em>: nonexistent list.
' \
\
"ERROR 'test-0001-w42-atsm':50: def (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atsm':51: defa (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atsm':52: defx (presumably) needs (at least) 2 argument(s)
ERROR 'test-0001-w42-atsm':53: defa1: 2 is not a valid array index
ERROR 'test-0001-w42-atsm':54: defx1 takes 2 argument(s)
ERROR 'test-0001-w42-atsm':55: MODTIME_SLOCAL does not take any argument(s)
ERROR 'test-0001-w42-atsm':56: MODTIME_ALOCAL: cannot modify builtin PI (variable) via push
ERROR 'test-0001-w42-atsm':57: NOW_SLOCAL does not take any argument(s)
ERROR 'test-0001-w42-atsm':58: NOW_ALOCAL: cannot modify builtin PI (variable) via push
"

## }}}
## pi-if {{{

tcase 'pi-if' 0002-w42-atsm \
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
<p>defx1-c1 defx1-arg1 defx1-c2 defx1-arg2</p>
' \
\
''

## }}}
## undef {{{

tcase 'undef' 0003-w42-atsm \
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
"ERROR 'test-0003-w42-atsm':10: undef takes 1 argument(s), has 0
ERROR 'test-0003-w42-atsm':12: undef: cannot undef builtin PI (variable): undef
ERROR 'test-0003-w42-atsm':14: undef: no such variable: def2
ERROR 'test-0003-w42-atsm':16: undef: no such variable: defx2
"

## }}}
## lref,lreft, href,hreft {{{

tcase 'lref/lreft/href/hreft' 0004-w42-atsm \
'
PATH = ../
THIS = <?lref ../da?>
THIS2 = <?lref <^PATH^>da?>
THIST = <?lreft dubi://du/../da<>dudadadu?>
THIST2 = <?lreft dubi://du/<^PATH^>da<>dudadadu?>
<?begin?>

<?lref http://www.netbsd.org?>
<?lreft http://www.netbsd.org<><em>NetBSD</em>?>

<?href http://www.freebsd.org?>
<?hreft http://www.freebsd.org<>FreeBSD?>

<?def WWW_PREFIX<><strong>WWW!</strong>?>
<?href http://www.freebsd.org?>
<?hreft http://www.freebsd.org<>FreeBSD?>

<?def WWW_PREFIX<>"a"?><?def WWW_SUFFIX<>"u"?>
<?href nope?>
<?hreft nope<><em title="SUB">FreeBSD</em>?>

## ERROR
<?lref a<>b?>
<?lreft a<>b<>c?>
<?href a<>b?>
<?hreft a<>b<>c?>

<?THIS?><?THIS2?>
<?THIST?>
<?THIST2?>
<?end?>' \
\
'<a href="http://www.netbsd.org">http://www.netbsd.org</a>
<a href="http://www.netbsd.org" title="NetBSD"><em>NetBSD</em></a>
<a href="http://www.freebsd.org">http://www.freebsd.org</a>
<a href="http://www.freebsd.org" title="FreeBSD">FreeBSD</a>
<a href="http://www.freebsd.org"><strong>WWW!</strong>http://www.freebsd.org</a>
<a href="http://www.freebsd.org" title="FreeBSD"><strong>WWW!</strong>FreeBSD</a>
<a href="nope">"a"nope"u"</a>
<a href="nope" title="FreeBSD">"a"<em title="SUB">FreeBSD</em>"u"</a>
<a href="../da">../da</a><a href="../da">../da</a>
<a href="dubi://du/../da" title="dudadadu">dudadadu</a>
<a href="dubi://du/../da" title="dudadadu">dudadadu</a>
' \
\
"ERROR 'test-0004-w42-atsm':24: lref takes 1 argument(s), has 2
ERROR 'test-0004-w42-atsm':25: lreft takes 2 argument(s), has 3
ERROR 'test-0004-w42-atsm':26: href takes 1 argument(s), has 2
ERROR 'test-0004-w42-atsm':27: hreft takes 2 argument(s), has 3
"

## }}}
## ?ifdef?.. {{{

tcase 'ifdef/...' 0005-w42-atsm \
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

<?ifdef 0?>1<?else?>
2<?fi?>3<?ifndef 0?>
4<?else?>5<?fi?>6<?ifndef 0?>7<?else?>
8<?fi?>9

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
23578:)
23
467
9
' \
\
"ERROR 'test-0005-w42-atsm':109: ifn?def: was started here, but where's the <?fi?>?
ERROR 'test-0005-w42-atsm':109: ifn?def: was started here, but where's the <?fi?>?
"

## }}}
## ?x?include?.. {{{

echo '<?begin?>1.1<?include test-0006-2?>1.2<?end?>AFTER END' > ./test-0006-1
echo '<?begin?>2.1<?include test-0006-3?>2.2<?end?>AFTER END' > ./test-0006-2
echo '
MYVAR = :
<?begin?><?MYVAR?><?end?>AFTER END' > ./test-0006-3
echo '
MYVAR = )
<?begin?>
4.1
<?include test-0006-3?><?MYVAR?>
4.2
<?end?>' > ./test-0006-4
printf '<?begin?>;<?end?>AFTER END' > ./test-0006-5

echo 'Embedded file <?def crossfile<>with?><?crossfile?> NL' > ./test-0006-6
printf 'And an embedded file <?crossfile?>out NL' > ./test-0006-7

tcase 'x?include' 0006-w42-atsm \
'<?begin?>
START<?include test-0006-1?>END
<?include test-0006-4?>
5.1
<?include test-0006-5?>
5.2<?include test-0006-5?>5.3
:<?xinclude test-0006-6?>-<?xinclude test-0006-7?>.
Passed <?crossfile?><?undef crossfile?>out errors.
<?end?>' \
\
'START1.12.1:2.21.2END
4.1
:)
4.2
5.1
;
5.2;5.3
:Embedded file with NL
-And an embedded file without NL.
Passed without errors.
' \
\
''

tcase 'x?include (exclusive content)' 6.1-w42-atsm \
'<?begin?>
<?include test-0006-5?>
<?end?>' \
\
';
' \
\
''

# }}}
## ?(raw|frank)_include?.. {{{

printf '<1\n >2\n&3\n' > ./test-0007-1
printf '&amp;&4\n  &gt;>5\n\n<&lt;&amp6\n' > ./test-0007-2
printf '7' > ./test-0007-3
printf '8\n9' > ./test-0007-4

tcase 'raw_include (direct I/O)' 0007-w42-atsm \
'<?begin?>
<?raw_include test-0007-1?>
START<?raw_include test-0007-1?>MID<?raw_include test-0007-2?>END
START<?raw_include test-0007-3?>MID<?raw_include test-0007-4?>END
<?raw_include test-0007-3?>
<?raw_include test-0007-4?>
<?end?>' \
\
'<1
 >2
&3
START<1
 >2
&3
MID&amp;&4
  &gt;>5

<&lt;&amp6
END
START7MID8
9END
7
8
9
' \
\
''

tcase 'raw_include (direct I/O, I)' 7.1-w42-atsm \
'<?begin?>
<?raw_include test-0007-3?>
<?end?>' \
\
'7
' \
\
''

tcase 'raw_include (direct I/O, II)' 7.2-w42-atsm \
'<?begin?>
<?raw_include test-0007-4?>
<?end?>' \
\
'8
9
' \
\
''

tcase 'frank_include (direct I/O, HTML escaping)' 7.3-w42-atsm \
'<?begin?>
<?frank_include test-0007-1?>
START<?frank_include test-0007-1?>MID<?frank_include test-0007-2?>END
START<?frank_include test-0007-3?>MID<?frank_include test-0007-4?>END
<?frank_include test-0007-3?>
<?frank_include test-0007-4?>
<?end?>' \
\
'&lt;1
 &gt;2
&amp;3
START&lt;1
 &gt;2
&amp;3
MID&amp;&amp;4
  &gt;&gt;5

&lt;&lt;&amp;amp6
END
START7MID8
9END
7
8
9
' \
\
''

# }}}
## pre/xpre/xcdata.. {{{

# (Note: 's' enabled)
tcase 'pre/xpre/xcdata' 0008-w42-atm \
'<?begin?>
	1. Beware of bugs in the above code;             
<?pre?>

     I   
	have  
		only       
			proved 
		it


	correct,          

<?pre end?>
not tried it.

	2. Beware of bugs in the above code;             
<pre><?pre?>

     I   
	have  
		only       
			proved 
		it


	correct,          

<?pre end?></pre>
not tried it.

	3. Beware of bugs in the above code;             
<?pre?><pre>

     I   
	have  
		only       
			proved 
		it


	correct,          

</pre><?pre end?>
not tried it.

	4. Beware of bugs in the above code;             
<?pre?>    I   
	have  
		only       
			proved 
		it

	correct,<?pre end?>not tried it.

	5. Beware of bugs in the above code;             
<?xpre?>

     I   
	have  
		only       
			proved 
		it


	correct,          

<?xpre end?>
not tried it.

	6. Beware of bugs in the above code;<?xpre?>    I   
	have  
		only       
			proved 
		it


	correct,<?xpre end?>not tried it.

7. Beware of bugs in the above code;
<?xpre?>    I   
	have  
		only       
			proved 
		it

	correct,<?xpre end?>
not tried it.

	8. Beware of bugs in the above code;             
<?xcdata?>

     I   
	have  
		only       
			proved 
		it


	correct,          

<?xcdata end?>
not tried it.

	9. Beware of bugs in the above code;<?xcdata?>    I   
	have  
		only       
			proved 
		it


	correct,<?xcdata end?>not tried it.

10. Beware of bugs in the above code;
<?xcdata?>    I   
	have  
		only       
			proved 
		it

	correct,<?xcdata end?>
not tried it.

<?end?>' \
\
'1. Beware of bugs in the above code;

     I
	have
		only
			proved
		it


	correct,

not tried it.
2. Beware of bugs in the above code;
<pre>

     I
	have
		only
			proved
		it


	correct,

</pre>
not tried it.
3. Beware of bugs in the above code;
<pre>

     I
	have
		only
			proved
		it


	correct,

</pre>
not tried it.
4. Beware of bugs in the above code;
    I
	have
		only
			proved
		it

	correct,not tried it.
5. Beware of bugs in the above code;
<pre>

     I
	have
		only
			proved
		it


	correct,

</pre>
not tried it.
6. Beware of bugs in the above code;<pre>    I
	have
		only
			proved
		it


	correct,</pre>not tried it.
7. Beware of bugs in the above code;
<pre>    I
	have
		only
			proved
		it

	correct,</pre>
not tried it.
8. Beware of bugs in the above code;
<pre><![CDATA[

     I
	have
		only
			proved
		it


	correct,

]]></pre>
not tried it.
9. Beware of bugs in the above code;<pre><![CDATA[    I
	have
		only
			proved
		it


	correct,]]></pre>not tried it.
10. Beware of bugs in the above code;
<pre><![CDATA[    I
	have
		only
			proved
		it

	correct,]]></pre>
not tried it.
' \
\
''

# }}}
## x?perl/x?sh {{{

echo 'When the Blitzkrieg raged' > ./test-0009-1
echo 'And the bodies stank' > ./test-0009-2

tcase 'x?perl/x?sh' 0009-w42-atsm \
'PERL = perl(1)
SH = sh(1)
<?begin?>
Hello, <?PERL?>.
<?perl?>
my $lmd = "Tue Dec  4 11:49:44 2012";
my $gmd = "Tue Dec  4 10:49:44 2012";

print <<__EOT__;
MYSELF = <?PERL?>
${BEGIN}
Hi ${PIS}MYSELF?>!

It is ${lmd}.
<?raw_include test-0009-1?>
That is ${gmd} UTC!

${END}
__EOT__
<?perl end?>

Hello, <?SH?>.
<?sh?>
lmd="Tue Dec  4 11:49:44 2012"
gmd="Tue Dec  4 10:49:44 2012"

echo "
MYSELF = <?SH?>
${BEGIN}
Hi ${PIS}MYSELF?>!

It is ${lmd}.
<?raw_include test-0009-2?>
That is ${gmd} UTC!

${END}
"
<?sh end?>

<?perl?>
my $perls = "perl string";

print <<__EOT__;
${BEGIN}
$perls
<?pre?>
	HAHAHA
<?pre end?>
$perls${PIS}pre?>   HOHOHO${PIS}pre end?>$perls
__EOT__

print "$perls${PIS}pre?>   HIHIHI${PIS}pre end?>$perls\n";
print "${END}\n";
<?perl end?>

<?sh?>
echo "${BEGIN}"
echo pipe | tr "[:lower:]" "[:upper:]"
echo "${END}"
<?sh end?>

:<?xperl?>
print "Embedded sentence ${PIS}def crossfile<>with?>${PIS}crossfile?> NL\n";
print "And an embedded sentence ${PIS}crossfile?>out NL";
<?xperl end?>.
Passed <?crossfile?><?undef crossfile?>out errors.
:<?xsh?>
echo "Embedded sentence ${PIS}def crossfile<>with?>${PIS}crossfile?> NL"
printf "And an embedded sentence ${PIS}crossfile?>out NL"
<?xsh end?>.
Passed <?crossfile?><?undef crossfile?>out errors.
<?end?>' \
\
'Hello, perl(1).
Hi perl(1)!
It is Tue Dec  4 11:49:44 2012.
When the Blitzkrieg raged
That is Tue Dec  4 10:49:44 2012 UTC!
Hello, sh(1).
Hi sh(1)!
It is Tue Dec  4 11:49:44 2012.
And the bodies stank
That is Tue Dec  4 10:49:44 2012 UTC!
perl string
HAHAHA
perl string   HOHOHOperl string
perl string   HIHIHIperl string
PIPE
:Embedded sentence with NL
And an embedded sentence without NL.
Passed without errors.
:Embedded sentence with NL
And an embedded sentence without NL.
Passed without errors.
' \
\
''

tcase 'Oneline document (perl(1))' 9.1-w42-atsm \
'<?begin?>START<?perl?>print "${BEGIN}in${END}"<?perl end?>END<?end?>' \
\
'STARTinEND
' \
\
''

tcase 'Oneline document (sh(1))' 9.2-w42-atsm \
'<?begin?>START<?sh?>printf "${BEGIN}in${END}"<?sh end?>END<?end?>' \
\
'STARTinEND
' \
\
''

# }}}
## mode {{{

tcase 'mode (but do not use it)' 0010-w42-atsm \
'<?begin?>
  # Comment
   Hello, Honey   \\
	Sugar Candy	\\
 Girl

    # Comment
<?mode icews?>
  # Comment
   Hello, Honey   \\
	Sugar Candy	\\
 Girl

    # Comment
<?mode %%?>
  # Comment
   Hello, Honey   \\
	Sugar Candy	\\
 Girl

    # Comment
<?end?>' \
\
'Hello, Honey   Sugar Candy	Girl

  # Comment
   Hello, Honey   \\
	Sugar Candy	\\
 Girl

    # Comment
Hello, Honey   Sugar Candy	Girl
' \
\
''

## }}}
## MarkLo {{{

printf '<?begin?>START\\c{t{e\\}st}\\c{tt}\\i{em}\\b{strong}\\u{u}\\i{I \\b{really \\u{{love\\}} you}, baby!}END\n\\a{xname}\\l{http://plan9.bell-labs.com/plan9/}\\b{OPEN-ERROR<?end?>\n' > ./test-0042-w42-ats

tcase 'MarkLo expansion (disable mode: m)' 0042-w42-ats \
'' \
\
'START<tt>t{e}st</tt><tt>tt</tt><em>em</em><strong>strong</strong><u>u</u><em>I <strong>really <u>{love}</u> you</strong>, baby!</em>END
<a name="xname"></a><a href="http://plan9.bell-labs.com/plan9/">http://plan9.bell-labs.com/plan9/</a>' \
\
"ERROR 'test-0042-w42-ats':2: MarkLo: \\\\b not closed (missing right brace)
"

## }}}
## Whitespace normalization {{{

tcase 'Whitespace normalization (disable mode: s)' 0043-w42-at \
'<?begin?>
  1   2		3		
  START   c{tt}			i{em}  b{strong} 	u{u}   \\
    END   
boing        bum         tschak
<?xpre?>
  1   2		3		
  START   c{tt}			i{em}  b{strong} 	u{u}   \\
    END   
boing        bum         tschak
<?xpre end?>
  1   2		3		
  START   c{tt}			i{em}  b{strong} 	u{u}   \\
    END   
boing        bum         tschak
<?end?>' \
\
'1 2 3
START c{tt} i{em} b{strong} u{u} END
boing bum tschak
<pre>
  1   2		3
  START   c{tt}			i{em}  b{strong} 	u{u}   \\
    END
boing        bum         tschak
</pre>
1 2 3
START c{tt} i{em} b{strong} u{u} END
boing bum tschak
' \
\
''

## }}}
## Automatic paragraphs {{{

tcase 'BAD (soup joining) but OK Automatic paragraphs (disable mode: a)' 0044-w42-t \
'<?begin?>
1 no empties before.

2 empties before and after.

3 empties before but not after.
because, yeah, this is a complete textblock.

4 No, i will not use the lazy fox or any ipsum.
<?xpre?>
buum
<?xpre end?>

<p>
5 this is yet a paragraph!
</p>

6 empties before and after.

7 empties before and after.

<?mode wt?>\\



<?mode %%?><?mode at?>

8 empties before and after, but no AUTOPAR.

<?mode %%?>

9 empties before and after.

= H1

== H2

=== H3

==== H4

===== H5

====== H6
For sure.

======Not H6

* Should be a list item.

* Should be yet another list item;
that continues.
* Should not be an item, but continue.

*Should not be an item.

1. Should be a numbered list, 1.

55. Should be a numbered list, 55.

100. Should be a numbered list.<p>100.</p>

11.Should not be a numbered list.

----

-----

------

<p>------</p>

_ Should be a blockquote.

_ \\i{Should be a second blockquote;\\
that continues.}
_ Should not be a blockquote, but continue.

_Should not be a blockquote.

<dl><dt>Handmade dt</dt><dd>In dd.

Yeah, we can have automatic paragraphs in handmade dd.

_ And blockquotes, too.
  Really.

_ And blockquote continuations.
  Inuations.

</dd></dl>

@ A definition list term. @ A definition list
item,
i would say.

@ Second dt. @\\
Second dd.

@ Third dt. @
Third dd.

@Not fourth dt. @

\\i{Enclosed in &lt;em&gt;, but still autpar.}

\\a{anchored}Begins with anchor, but is still autopar.

Ends with &lt;strong&gt;, but is still \\b{autopar.}

13 empties before but not after.
<?end?>' \
\
'1 no empties before.
<p>2 empties before and after.</p>
<p>3 empties before but not after.
because, yeah, this is a complete textblock.</p>
4 No, i will not use the lazy fox or any ipsum.
<pre>
buum
</pre>
<p>
5 this is yet a paragraph!
</p>
<p>6 empties before and after.</p>
<p>7 empties before and after.</p>



8 empties before and after, but no AUTOPAR.
<p>9 empties before and after.</p>
<h1>H1</h1>
<h2>H2</h2>
<h3>H3</h3>
<h4>H4</h4>
<h5>H5</h5>
<h6>H6
For sure.</h6>
<p>======Not H6</p>
<ul><li><p>Should be a list item.</p></li>
<li><p>Should be yet another list item;
that continues.
* Should not be an item, but continue.</p></li>
</ul><p>*Should not be an item.</p>
<ol><li value="1"><p>Should be a numbered list, 1.</p></li>
<li value="55"><p>Should be a numbered list, 55.</p></li>
<li value="100"><p>Should be a numbered list.<p>100.</p></p></li>
</ol><p>11.Should not be a numbered list.</p>
<p>----</p>
<hr />
<hr />
<p>------</p>
<blockquote><p>Should be a blockquote.</p>
<p><em>Should be a second blockquote;that continues.</em>
_ Should not be a blockquote, but continue.</p>
</blockquote><p>_Should not be a blockquote.</p>
<dl><dt>Handmade dt</dt><dd>In dd.
<p>Yeah, we can have automatic paragraphs in handmade dd.</p>
<blockquote><p>And blockquotes, too.
Really.</p>
<p>And blockquote continuations.
Inuations.</p>
</blockquote></dd></dl>
<dl><dt>A definition list term.</dt><dd><p>A definition list
item,
i would say.</p></dd>
<dt>Second dt.</dt><dd><p>Second dd.</p></dd>
<dt>Third dt.</dt><dd><p>
Third dd.</p></dd>
</dl><p>@Not fourth dt. @</p>
<p><em>Enclosed in &lt;em&gt;, but still autpar.</em></p>
<p><a name="anchored"></a>Begins with anchor, but is still autopar.</p>
<p>Ends with &lt;strong&gt;, but is still <strong>autopar.</strong></p>
13 empties before but not after.
' \
\
''

tcase 'OK BUT BAD (soup joining) Automatic paragraphs (disable mode: a)' 0045-w42-t \
'<?begin?>
1 no empties before.

2 empties before and after.

3 empties before but not after.
because, yeah, this is a complete textblock.

4 No, i will not use the lazy fox or any ipsum.
<?xpre?>
buum
<?xpre end?>

<p>
5 this is yet a paragraph!
</p>

6 empties before and after.

7 empties before and after.

<?mode wt?>\\



<?mode %%?><?mode at?>

8 empties before and after, but no AUTOPAR.

<?mode %%?>

9 empties before and after.

= H1

== H2

=== H3

==== H4

===== H5

====== H6
For sure.

======Not H6

* Should be a list item.

* Should be yet another list item;
that continues.
* Should not be an item, but continue.

*Should not be an item.

1. Should be a numbered list, 1.

55. Should be a numbered list, 55.

100. Should be a numbered list.<p>100.</p>

11.Should not be a numbered list.

----

-----

------

<p>------</p>

_ Should be a blockquote.

_ \\i{Should be a second blockquote;\\
that continues.}
_ Should not be a blockquote, but continue.

_Should not be a blockquote.

<dl><dt>Handmade dt</dt><dd>In dd.

Yeah, we can have automatic paragraphs in handmade dd.

_ And blockquotes, too.
  Really.

_ And blockquote continuations.
  Inuations.

</dd></dl>

@ A definition list term. @ A definition list
item,
i would say.

@ Second dt. @\\
Second dd.

@ Third dt. @
Third dd.

@Not fourth dt. @

\\i{Enclosed in &lt;em&gt;, but still autpar.}

\\a{anchored}Begins with anchor, but is still autopar.

Ends with &lt;strong&gt;, but is still \\b{autopar.}

13 empties before but not after.
<?end?>' \
\
'1 no empties before.
<p>2 empties before and after.</p>
<p>3 empties before but not after.
because, yeah, this is a complete textblock.</p>
4 No, i will not use the lazy fox or any ipsum.
<pre>
buum
</pre>
<p>
5 this is yet a paragraph!
</p>
<p>6 empties before and after.</p>
<p>7 empties before and after.</p>



8 empties before and after, but no AUTOPAR.
<p>9 empties before and after.</p>
<h1>H1</h1>
<h2>H2</h2>
<h3>H3</h3>
<h4>H4</h4>
<h5>H5</h5>
<h6>H6
For sure.</h6>
<p>======Not H6</p>
<ul><li><p>Should be a list item.</p></li>
<li><p>Should be yet another list item;
that continues.
* Should not be an item, but continue.</p></li></ul>
<p>*Should not be an item.</p>
<ol><li value="1"><p>Should be a numbered list, 1.</p></li>
<li value="55"><p>Should be a numbered list, 55.</p></li>
<li value="100"><p>Should be a numbered list.<p>100.</p></p></li></ol>
<p>11.Should not be a numbered list.</p>
<p>----</p>
<hr />
<hr />
<p>------</p>
<blockquote><p>Should be a blockquote.</p>
<p><em>Should be a second blockquote;that continues.</em>
_ Should not be a blockquote, but continue.</p></blockquote>
<p>_Should not be a blockquote.</p>
<dl><dt>Handmade dt</dt><dd>In dd.
<p>Yeah, we can have automatic paragraphs in handmade dd.</p>
<blockquote><p>And blockquotes, too.
Really.</p>
<p>And blockquote continuations.
Inuations.</p></blockquote>
</dd></dl>
<dl><dt>A definition list term.</dt><dd><p>A definition list
item,
i would say.</p></dd>
<dt>Second dt.</dt><dd><p>Second dd.</p></dd>
<dt>Third dt.</dt><dd><p>
Third dd.</p></dd></dl>
<p>@Not fourth dt. @</p>
<p><em>Enclosed in &lt;em&gt;, but still autpar.</em></p>
<p><a name="anchored"></a>Begins with anchor, but is still autopar.</p>
<p>Ends with &lt;strong&gt;, but is still <strong>autopar.</strong></p>
13 empties before but not after.
' \
\
''

## }}}

## "Deep dirhier": (no) cross-file variables, incdir, chdir {{{

(	WEB42=../s-web42 RC=
	mkdir -p test-dirhier/l1/l2/l3 || {
		echo >&2 'FAILED to create dirhier for final test'
		exit 11
	}
	cd test-dirhier || {
		echo >&2 'FAILED to chdir to test-dirhier for final test'
		exit 12
	}
	CWD=`pwd`

	echo > ./config.rc \
'PERL = <?perl?>require Cwd; print "${BEGIN}<?FILE?><", Cwd->getcwd, ">${END}"\
<?perl end?>
FILE =   -should-not-be-seen-  
TOPMENU @= {TOP}'

	echo \
'TOPMENU @= [11]
FILE = (11)
<?begin?><?PERL?><?include l2/f1?><?include l2/f2?><?TOPMENU loop?><?end?>' \
	> l1/f1

	echo \
'TOPMENU @= [21]
FILE = (21)
<?begin?><?PERL?><?include l3/f1?><?include l3/f2?><?TOPMENU loop?><?end?>' \
	> l1/l2/f1

	echo \
'TOPMENU @= [22]
FILE = (22)
<?begin?><?PERL?><?raw_include l3/f3?><?TOPMENU loop?><?end?>' \
	> l1/l2/f2

	echo \
'TOPMENU @= [31]
FILE = (31)
<?begin?><?PERL?><?include ../f2?><?TOPMENU loop?><?end?>' \
	> l1/l2/l3/f1

	echo \
'TOPMENU @= [32]
FILE = (32)
<?begin?><?PERL?><?include ../f2?><?TOPMENU loop?><?end?>' \
	> l1/l2/l3/f2

	printf 'Jo-Ho-Ho' > l1/l2/l3/f3

	tcase 'FINALLY: deep dirhier' 4221-w42 \
'FILE = -no-no-
<?begin?>START<?FILE?><?include l1/f1?>END<?end?>' \
\
"START-no-no-\
(11)<${CWD}>\
(21)<${CWD}>\
(31)<${CWD}>\
(22)<${CWD}>Jo-Ho-Ho\
{TOP}[11][21][31][22]\
{TOP}[11][21][31]\
(32)<${CWD}>\
(22)<${CWD}>Jo-Ho-Ho\
{TOP}[11][21][32][22]\
{TOP}[11][21][32]\
{TOP}[11][21]\
(22)<${CWD}>Jo-Ho-Ho\
{TOP}[11][22]\
{TOP}[11]\
END
" \
\
''

	[ ${errs} -eq 0 ]
)

# }}}

[ ${errs} -eq 0 ] && exit 0 || {
	printf "=======\nThere were ${errs} error(s)\n"
	exit 42
}
