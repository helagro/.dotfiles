#!/bin/zsh

function main {
    local detach_time=$(tl.sh 'routines/detach/start?sep=%3A')
    local sleep_time_yd=$(is sleep_start 1 1 | jq '.[]' | hm)
    local bed_minus_detach=$(time_diff.sh -mp "$detach_time" "$sleep_time_yd")
}

main
