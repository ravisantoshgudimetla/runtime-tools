#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

RUNTIME="runc"
KEEP=0

usage() {
	echo "$0 -r <runtime> -h -k"
}

error() {
	echo $*
	exit 1
}

info() {
	echo $*
}

while getopts "r:kh" opt; do
	case "${opt}" in
		r)
			RUNTIME=${OPTARG}
			;;
		h)
			usage
			exit 0
			;;
		k)
			KEEP=1
			;;
		\?)
			usage
			exit 1
			;;
	esac
done

info "-----------------------------------------------------------------------------------"
info "                         VALIDATING RUNTIME: ${RUNTIME}"
info "-----------------------------------------------------------------------------------"

if ! command -v ${RUNTIME} > /dev/null; then
	error "Runtime ${RUNTIME} not found in the path"
fi

TMPDIR=$(mktemp -p /testroot -d)
TESTDIR=${TMPDIR}/busybox
mkdir -p ${TESTDIR}

cleanup() {
	if [ "${KEEP}" -eq 0 ]; then
		rm -rf ${TMPDIR}
	else
		info "Remove the test directory ${TMPDIR} after use"
	fi
}
trap cleanup EXIT

tar -xf  rootfs.tar.gz -C ${TESTDIR}
cp runtimetest ${TESTDIR}

TESTCMD="${RUNTIME} start"

pushd $TESTDIR > /dev/null
ocitools generate --args /runtimetest
popd > /dev/null

pushd $TESTDIR > /dev/null
if ! ${TESTCMD}; then
	error "Runtime ${RUNTIME} failed validation"
else
	info "Runtime ${RUNTIME} passed validation"
fi
popd > /dev/null
