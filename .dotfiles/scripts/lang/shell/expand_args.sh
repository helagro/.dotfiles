#!/bin/bash

expanded_args=()
for arg in "$@"; do
    if [[ "$arg" =~ ^-([A-Za-z]+)$ && ! "$arg" =~ ^-- ]]; then
        flags="${arg:1}"
        for ((i = 0; i < ${#flags}; i++)); do
            expanded_args+=("-${flags:i:1}")
        done
    else
        expanded_args+=("$arg")
    fi
done

echo "${expanded_args[@]}"
