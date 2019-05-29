#!/usr/bin/env bash

# Heavily based on the ovotech/clair-scanner orb at https://circleci.com/orbs/registry/orb/ovotech/clair-scanner

DB=$(docker run -p 5432:5432 -d arminc/clair-db:latest)
CLAIR=$(docker run -p 6060:6060 --link $DB:postgres -d arminc/clair-local-scan:latest)
CLAIR_SCANNER=$(docker run -v /var/run/docker.sock:/var/run/docker.sock -d ovotech/clair-scanner@sha256:6fd950030d971317b3b8ee5efcc45f0c3cf624b68cf741c83f787a9dde9917cc tail -f /dev/null)

clair_ip=$(docker exec -it $CLAIR hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
scanner_ip=$(docker exec -it $CLAIR_SCANNER hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

EXIT_STATUS=0

function scan() {
    local image=$1

    if ! docker exec -it $CLAIR_SCANNER clair-scanner --ip ${scanner_ip} --clair=http://${clair_ip}:6060 -t "$THRESHOLD" --report "/report.json" $WHITELIST "$image"; then
        EXIT_STATUS=1
    fi
}

scan "$IMAGE"

if [ "$FAIL_ON_VULN" == "false" ]; then
    exit 0
else
    exit $EXIT_STATUS
fi
