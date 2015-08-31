
# check dependencies
(
    type docker &>/dev/null || ( echo "docker is not available"; exit 1 )
    type curl &>/dev/null || ( echo "curl is not available"; exit 1 )
)>&2


function get_jenkins_port {
    docker port $1 8080 | cut -d: -f2
}

function test_url {
    curl --output /dev/null --silent --head --fail --connect-timeout 2 --max-time 5 http://localhost:$(get_jenkins_port $1)$2
}

function wait_for_jenkins {
    local CONTAINER_NAME=$1
    local COUNTDOWN=40
    until $(test_url $CONTAINER_NAME /) >&2 || [ $COUNTDOWN -le 0 ]; do
        COUNTDOWN=$(( $COUNTDOWN - 1 ))
        sleep 3
    done
    sleep 2
    curl --head --fail --connect-timeout 2 --max-time 5 http://localhost:$(get_jenkins_port $CONTAINER_NAME)/ >&2
}