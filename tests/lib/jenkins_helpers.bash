function get_jenkins_url {
    echo "http://localhost:$(docker port $SUT_CONTAINER 8080 | cut -d: -f2)"
}

function jenkins_url {
    run curl --output /dev/null --silent --head --fail --connect-timeout 30 --max-time 60 $(get_jenkins_url)$1
    [ "$status" = "0" ] || (\
        echo "URL $(get_jenkins_url)$1 failed" >&2
        echo "output: $output" >&2
        false
    )
}

# assert that last build of given job $1 succeeded
function jenkins_job_success {
    local url=$(get_jenkins_url)/job/$1/lastBuild/api/json

    # wait while job is running
    function get_building {
        curl -sS $url | jq '.building'
    }
    retry 10 5 assert 'false' get_building

    function get_result {
        curl -sS $url | jq '.result'
    }
    assert '"SUCCESS"' get_result || (\
        curl -sS $url | jq '.result' >&2
        false
    )
}

# start a build of a given jenkins job
function jenkins_build_job {
    local url=$(get_jenkins_url)/job/$1/build
    local http_status=$(curl -X POST --output /dev/null -w "%{http_code}" --fail --connect-timeout 30 --max-time 60 $url)
    [ "$http_status" = "201" ] || (\
        echo "HTTP status: $http_status" >&2
        false
    )
}