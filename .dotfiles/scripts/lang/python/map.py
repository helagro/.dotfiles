#!/usr/bin/env python3

import json
import sys
from typing import cast

# file op -------------------------------------------------------------------- #


def load_state():
    with open(mapFile, "r") as f:
        return json.load(f)


def save_state(state):
    with open(mapFile, "w") as f:
        json.dump(state, f, indent=2)


# property op ---------------------------------------------------------------- #


def get_value(keys: list[str]):
    item = load_state()

    for key in keys:
        if key not in item:
            return None

        item = item[key]

    return item


def set_value(keys: list[str], value, unset: bool = False):
    state = load_state()

    d = state
    for key in keys[:-1]:
        if key not in d or not isinstance(d[key], dict):
            d[key] = {}
        d = d[key]

    if unset:
        del d[keys[-1]]
    else:
        d[keys[-1]] = value

    save_state(state)


# helpers -------------------------------------------------------------------- #


def calc_value(value: str) -> object:
    true_values = {"true", "yes", "on"}
    false_values = {"false", "no", "off"}

    value_lower = value.lower()
    if value_lower in true_values:
        return True
    elif value_lower in false_values:
        return False
    elif value_lower == "null":
        return None
    elif value.isdigit() or (value.startswith("-") and value[1:].isdigit()):
        return int(value)
    else:
        try:
            value_parsed = json.loads(value)
            if isinstance(value_parsed, (dict, list)) or value_parsed is None:
                return value_parsed
        except Exception:
            return value


# main ----------------------------------------------------------------------- #


def main():
    args = sys.argv[2:]
    do_silent = False

    if args and args[0] == "-s":
        do_silent = True
        args = args[1:]

    args_len = len(args)

    if args:
        if args[0] == "set":
            if args_len != 3:
                print("Usage: state.py set <key> <value>")
                sys.exit(1)

            key = args[1]
            value = calc_value(args[2])

            set_value(key.split("."), value)
            sys.exit(0)

        elif args[0] == "unset":
            if args_len != 2:
                print("Usage: state.py unset <key>")
                sys.exit(1)

            key = args[1]

            try:
                set_value(key.split("."), None, unset=True)
            except Exception:
                pass

            sys.exit(0)

        elif args[0] == "add":
            if args_len != 3:
                print("Usage: state.py add <key> <value>")
                sys.exit(1)

            key = args[1]
            value = calc_value(args[2])

            current_value = get_value(key.split("."))
            if current_value is None:
                current_value = []

            if not isinstance(current_value, list):
                print(f"Error: Current value for '{key}' is not a list.")
                sys.exit(1)

            current_value.append(value)
            set_value(key.split("."), current_value)
            sys.exit(0)

        elif args[0] == "inc":
            if args_len != 3:
                print("Usage: state.py inc <key> <amount>")
                sys.exit(1)

            key = args[1]
            amount = calc_value(args[2])

            current_value = get_value(key.split("."))
            if current_value is None:
                current_value = 0
            elif not isinstance(amount, int):
                print(f"Error: Amount to add for '{key}' is not an integer.")
                sys.exit(1)

            if not isinstance(current_value, int):
                print(f"Error: Current value for '{key}' is not an integer.")
                sys.exit(1)

            new_value = cast(int, current_value) + cast(int, amount)
            set_value(key.split("."), new_value)
            sys.exit(0)

    value = get_value(args[0].split(".") if args_len > 0 else args)
    if value is None and args_len > 1:
        value = calc_value(args[1])

    if not do_silent:
        if isinstance(value, str):
            print(value)
        else:
            print(json.dumps(value, indent=2))

    sys.exit(not value)


if __name__ == "__main__":
    mapFile = sys.argv[1]

    main()
