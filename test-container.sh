#!/bin/bash -e
#
# Test script to verify container is working correctly
#   - test that the container is started
#   - test that the deployment of the invoice process archive is successful
#   - test that the webapp login is working
#

function check_container_running {
    local container=${1:-camunda}
    local running=$(docker inspect --format="{{ .State.Running }}" $container)

    echo -n "status: Check container $container state"

    [ "$running" != "true" ] && (echo -e "\033[2K\rstatus: Container $container is not running (abort)"; return 1)

    echo -e "\033[2K\rstatus: Container $container is running"
}

function wait_for_deployment {
    local retries=${1:-20}
    local wait_time=${2:-3}

    echo -n "deploy: Grep log for deployment summary"
    for retry in $(seq $retries); do
        docker logs camunda 2>&1 | grep -q "Deployment summary for process archive 'camunda-invoice' of process application 'camunda-invoice'" && \
            echo -e "\033[2K\rdeploy: Deployment summary found ($retry/$retries)" && return 0
        if [ $retry -lt $retries ]; then
            echo -en "\033[2K\rdeploy: Deployment summary not found will wait for $wait_time seconds and retry ($retry/$retries)"
            sleep $wait_time
        else
            echo -e "\033[2K\rdeploy: Deployment summary not found (abort)"
        fi
    done

    return 2
}

function test_login {
    local app=${1:-cockpit}
    local retries=${2:-3}
    local wait_time=${3:-3}
    echo -n "webapp: Test $app login"

    curl --fail -s --retry $retries --retry-delay $wait_time --header "Accept: application/json" --data 'username=demo&password=demo' -o/dev/null http://localhost:8080/camunda/api/admin/auth/user/default/login/${app} || \
        (echo -e "\033[2K\rwebapp: Login $app failed (abort)"; return 3)

    echo -e "\033[2K\rwebapp: Login $app successful"
}

# check container state
check_container_running

# poll log for deployment summary
wait_for_deployment

# test webapp logins
test_login cockpit
test_login tasklist
test_login admin
