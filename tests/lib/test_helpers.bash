
# check dependencies
(
    type docker &>/dev/null || ( echo "docker is not available"; exit 1 )
    type curl &>/dev/null || ( echo "curl is not available"; exit 1 )
    type jq &>/dev/null || ( echo "jq is not available (https://stedolan.github.io/jq/)"; exit 1 )
)>&2

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
load ${DIR}/jenkins_helpers.bash
load ${DIR}/docker_helpers.bash

# use those options to enable the use of the docker command from a container
DOCKER_OPTS_ENABLING_DOCKER="-v $(which docker):/usr/bin/docker:ro \
    -v /usr/lib/x86_64-linux-gnu/libapparmor.so.1.1.0:/lib/x86_64-linux-gnu/libapparmor.so.1"


function assert {
    local expected_output=$1
    shift
    run "$@"
    [ "$output" = "$expected_output" ] || ( \
        echo "expected: \"$expected_output\", actual: \"$output\"" >&2; \
        false \
        )
}

# Retry a command $1 times until it succeeds. Wait $2 seconds between retries.
function retry {
    local attempts=$1
    shift
    local delay=$1
    shift
    local i

    for ((i=0; i < attempts; i++)); do
        run "$@"
        if [ "$status" -eq 0 ]; then
            return 0
        fi
        sleep $delay
    done

    echo "Command \"$@\" failed $attempts times. Status: $status. Output: $output" >&2
    false
}

# compare version $1 against $2
# results:
# - 0 : $1 == $2
# - 1 : $1 >  $2
# - 2 : $1 <  $2
# See http://stackoverflow.com/a/4025065/107049
function vercomp {
    if [[ $1 == $2 ]]
    then
        echo 0
        return
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo 1
            return
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo 2
            return
        fi
    done
    echo 0
}