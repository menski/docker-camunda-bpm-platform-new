#!/bin/bash -e

function check_container_running {
    local container=${1:-camunda}
    local running=$(docker inspect --format="{{ .State.Running }}" $container)

    echo "$container: Check container state"

    [ "$running" != "true" ] && (echo "$container: Container is not running"; return 1)

    echo "$container: Container is running"
}

function wait_for_deployment {
    local retries=${1:-20}
    local wait_time=${2:-3}

    for retry in $(seq $retries); do
        echo "$retry: Grep log for deployment summary"
        docker logs camunda 2>&1 | grep -q "ENGINE-08023 Deployment summary for process archive 'camunda-invoice'" && \
            echo "$retry: Deployment summary found" && return 0
        if [ $retry -lt $retries ]; then
            echo "$retry: Deployment summary not found will wait for $wait_time seconds and retry ($(expr $retries - $retry) retries left)"
            sleep $wait_time
        else
            echo "$retry: Deployment summary not found (abort)"
        fi
    done

    return 2
}

function test_login {
    local app=${1:-cockpit}
    local retries=${2:-3}
    local wait_time=${3:-3}
    echo "$app: Test login"

    curl --fail -s --retry $retries --retry-delay $wait_time  --data 'username=demo&password=demo' -D- -o/dev/null http://localhost:8080/camunda/api/admin/auth/user/default/login/${app} || \
        (echo "$app: Login failed (abort)"; return 3)

    echo "$app: Login successful"
}

# check container state
check_container_running

# poll log for deployment summary
wait_for_deployment

# test webapp logins
test_login cockpit
test_login tasklist
test_login admin
