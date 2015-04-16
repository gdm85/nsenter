
function create_env_args() {
	local PID="$1"
	echo -n "HOME=/root USER=root UID=0 LOGNAME=root USERNAME=root TERM=$TERM"
	## space is necessary
	echo -n " "
	## carefully filter out empty environment variables
	## Dockerfile does not allow clearing environment variables, so we will set them to ""
	cat /proc/$PID/environ | xargs -0 | sed -r -e 's~[A-Za-z0-9_]+=("")? ~~g'
	return ${PIPESTATUS[0]}
}

function docker_get_pid() {
	local PID
	local CID="$1"

	PID=$(docker inspect --format '{{printf "%.0f" .State.Pid}}' "$CID") || return $?

	if [[ ! "$PID" =~ ^[[:digit:]]+$ ]]; then
		return 1
	fi

	if [ $PID -eq 0 ]; then
		echo "'$CID' does not appear to be running" 1>&2
		return 2
	fi

	echo "$PID"
}

function docker_nsenter() {
	local PID
	local ENV
	local OPTS
	local NSE
	local CID="$1"
	shift 1

	PID=$(docker_get_pid "$CID") || return $?

	## environment override
	ENV="$(create_env_args $PID)" || return $?

	## get absolute path to nsenter
	set -o pipefail && \
	NSE=$(whereis -b nsenter | awk '{ print $2 }') || return $?
	test -z "$NSE" && return 2

	OPTS="--target $PID --mount --uts --ipc --net --pid -F"

	env --ignore-environment $ENV $NSE $OPTS -- "$@"
}
