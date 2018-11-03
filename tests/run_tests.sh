#!/usr/bin/env bash
set -u

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"


SUCCESS_COUNT=0
FAILURE_COUNT=0


# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "** Trapped CTRL-C"
    echo SUCCESS: ${SUCCESS_COUNT}
    echo FAILURE: ${FAILURE_COUNT}
    exit 2
}

echo "Running test suite for image ${IMAGE_NAME}"
for test_compose_file in test_*.yml; do
    cat <<EOT

-------------------------------------------------------------------------------
Running ${test_compose_file}
-------------------------------------------------------------------------------
EOT

    docker-compose -f "${test_compose_file}" up \
        --build \
        --force-recreate \
        --remove-orphans \
        --renew-anon-volumes \
        --exit-code-from sut \
        --abort-on-container-exit \
        sut
    [[ "$?" == "0" ]] && SUCCESS_COUNT=$(( SUCCESS_COUNT + 1 )) || FAILURE_COUNT=$(( FAILURE_COUNT + 1 ))
done

echo SUCCESS: ${SUCCESS_COUNT}
echo FAILURE: ${FAILURE_COUNT}

[[ "$FAILURE_COUNT" == "0" ]]
