#!/bin/bash

log() {
    local type="$1"
    shift
    local timestamp
    timestamp=$(date +"[%Y-%m-%d %H:%M:%S %Z]")
    echo "$timestamp [$type] $*"
}
