#!/bin/bash

docker run --rm -d --volume "${PWD}/test:/klap/test/" --name klap klap-cgo22 tail -f /dev/null
