#!/usr/bin/env python3

import json
import os
import sys

STATE_FILE = os.path.expanduser("~/.dotfiles/tmp/state.json")

# file op -------------------------------------------------------------------- #


def load_state():
    with open(STATE_FILE, "r") as f:
        return json.load(f)


def save_state(state):
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, indent=2)


# property op ---------------------------------------------------------------- #


def get_value(key):
    state = load_state()
    return state.get(key)


def set_value(key, value):
    state = load_state()
    state[key] = value
    save_state(state)


# helpers -------------------------------------------------------------------- #


def calc_value(value: str) -> int | bool | None:
    true_values = {"1", "true", "yes", "on"}
    false_values = {"0", "false", "no", "off"}

    value_lower = value.lower()
    if value_lower in true_values:
        return True
    elif value_lower in false_values:
        return False
    elif value_lower == "null":
        return None
    elif value.isdigit():
        return int(value)
    else:
        raise ValueError(f"Invalid value: {value}")


# main ----------------------------------------------------------------------- #


def main():
    args = sys.argv[1:]
    do_silent = False

    if args and args[0] == "-s":
        do_silent = True
        args = args[1:]

    if args and args[0] == "set":
        if len(args) != 3:
            print("Usage: state.py -s set <key> <value>")
            sys.exit(1)

        key = args[1]
        value = calc_value(args[2])

        set_value(key, value)
        sys.exit(0)

    if len(args) >= 1:
        key = args[0]
        value = get_value(key)
    else:
        value = load_state()

    if not do_silent:
        print(json.dumps(value))

    sys.exit(not value)


if __name__ == "__main__":
    main()
