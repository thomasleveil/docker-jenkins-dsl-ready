
# Removes container $1
function docker_clean {
	docker kill $1 &>/dev/null ||:
	sleep .1s
	docker rm -f $1 &>/dev/null ||:
	sleep .1s
}

# get the ip of docker container $1
function docker_ip {
	docker inspect --format '{{ .NetworkSettings.IPAddress }}' $1
}

# get the running state of container $1
# → true/false
# fails if the container does not exist
function docker_running_state {
	docker inspect -f {{.State.Running}} $1
}

# get the docker container $1 PID
function docker_pid {
	docker inspect --format {{.State.Pid}} $1
}

# asserts logs from container $1 contains $2
function docker_assert_log {
	local -r container=$1
	shift
	run docker logs $container
	assert_output -p "$*"
}

# wait for container $2 to contain a given text in its log
# $1 timeout in second
# $2 container
# $* text to wait for
function docker_wait_for_log {
	local -ir timeout_sec=$1
	shift
	local -r container=$1
	shift
	retry $(( $timeout_sec * 2 )) .5s docker_assert_log $container "$*"
}

# Create a docker container named $1 (or bats-docker-tcp) 
# which exposes the docker host unix socket over tcp.
function docker_tcp {
	local container_name="$1"
	[ "$container_name" = "" ] && container_name="bats-docker-tcp"
	docker rm -f bats-docker-tcp ||:
	docker run -d \
		--name $container_name \
		--expose 2375 \
		-v /var/run/docker.sock:/var/run/docker.sock \
		rancher/socat-docker
	docker -H tcp://$(docker_ip $container_name):2375 version
}
