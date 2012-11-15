#!/bin/sh -
#@ S-Web42 unit test

mkdir t && cd t || {
	echo >&2 'Cannot create and chdir into t estdir'
	exit 1
}
trap "cd .. ; rm -rf t" 0 1 2 15

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
	../s-web42 --eo test-${1} > test-out 2> test-err
	cmp -s test-out test-eout
	[ $? -ne 0 ] && o='STDOUT ' || o=
	cmp -s test-err test-eerr
	[ $? -ne 0 ] && e='STDERR ' || e=
	[ -z "${o}${e}" ] && echo "OK: ${tno}" || terr ${tno} "${o}${e}"
}

##



##

[ ${errs} -eq 0 ] && exit 0 || exit 42
