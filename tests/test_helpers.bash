
# check dependencies
(
    type docker &>/dev/null || ( echo "docker is not available"; exit 1 )
    type curl &>/dev/null || ( echo "curl is not available"; exit 1 )
)>&2

function jq_is_available_or_skip {
    type jq &>/dev/null || skip "jq is required"
}

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

function get_jenkins_url {
    echo "http://localhost:$(docker port $SUT_CONTAINER 8080 | cut -d: -f2)"
}

function test_url {
    run curl --output /dev/null --silent --head --fail --connect-timeout 30 --max-time 60 $(get_jenkins_url)$1
    if [ "$status" -eq 0 ]; then
        true
    else
        echo "URL $(get_jenkins_url)$1 failed" >&2
        echo "output: $output" >&2
        false
    fi
}
