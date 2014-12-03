
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

function docker_nsenter() {
	local PID
	local ENV
	local OPTS
	local NSE
	local CID="$1"
	shift 1

	PID=$(docker inspect --format "{{.State.Pid}}" "$CID") || return $?
	if [[ -z "$PID" || "$PID" == "<no value" || "$PID" == "0" ]]; then
		return 1
	fi

	## environment override
	ENV="$(create_env_args $PID)" || return $?

	## get absolute path to nsenter
	NSE=$(whereis -b nsenter | awk '{ print $2 }')
	test ${PIPESTATUS[0]} -eq 0 || return 1
	test -z "$NSE" && return 2

	OPTS="--target $PID --mount --uts --ipc --net --pid -F"

	env --ignore-environment $ENV $NSE $OPTS -- "$@"
}
