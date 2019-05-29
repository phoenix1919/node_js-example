#!/usr/bin/env bash
            
            REPORT_DIR=workspace/clair-reports
            mkdir $REPORT_DIR
            
            DB=$(docker run -p 5432:5432 -d arminc/clair-db:latest)
            CLAIR=$(docker run -p 6060:6060 --link $DB:postgres -d arminc/clair-local-scan:latest)
            CLAIR_SCANNER=$(docker run -v /var/run/docker.sock:/var/run/docker.sock -d ovotech/clair-scanner@sha256:6fd950030d971317b3b8ee5efcc45f0c3cf624b68cf741c83f787a9dde9917cc tail -f /dev/null)
            
            clair_ip=$(docker exec -it $CLAIR hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            scanner_ip=$(docker exec -it $CLAIR_SCANNER hostname -i | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
            
#            if [ -n $WHITELIST ]; then
#                cat "$WHITELIST"
#                docker cp "$WHITELIST" $CLAIR_SCANNER:/whitelist.yml
#            
#                WHITELIST="-w /whitelist.yml"
#            fi
            
            EXIT_STATUS=0
            
            function scan() {
                local image=$1
                mkdir -p "$REPORT_DIR/$(dirname $image)"
            
                docker pull "$image"
            
                if ! docker exec -it $CLAIR_SCANNER clair-scanner --ip ${scanner_ip} --clair=http://${clair_ip}:6060 -t "$THRESHOLD" --report "/report.json" $WHITELIST "$image"; then
                    EXIT_STATUS=1
                fi
            
                docker cp "$CLAIR_SCANNER:/report.json" "$REPORT_DIR/${image}.json"
            }
            
#            if [ -n "$IMAGE_FILE" ]; then
#                images=$(cat "$IMAGE_FILE")
#                for image in $images; do
#                    scan $image
#                done
#            else
#                scan "$IMAGE"
#            fi
            scan "$IMAGE"

            if [ "$FAIL_ON_VULN" == "false" ]; then
                exit 0
            else
                exit $EXIT_STATUS
            fi
