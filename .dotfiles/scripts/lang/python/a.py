import argparse
import csv
from dataclasses import dataclass
import sys
import json
import os
from datetime import datetime
import re


@dataclass
class Meta:
    count: int = 0


@dataclass
class GetCommand:
    index: int
    get_time: bool = False

    @staticmethod
    def from_code(code: str):
        get_time = 't' in code

        number_str = re.search(r'-?\d+', code)
        if not number_str:
            raise ValueError("Invalid code format - No number found")

        index = int(number_str.group())
        return GetCommand(index=index, get_time=get_time)


HISTORY_FILE = "/tmp/a_history.txt"
METADATA_FILE = "/tmp/a_meta.txt"

# ================================ COMMANDS ================================ #


def main():
    parser = argparse.ArgumentParser(prog="a.py", description="Backend for adding")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # add command
    add_parser = subparsers.add_parser("add", help="Add a name")
    add_parser.add_argument("content", help="content to add")
    add_parser.add_argument("-m", "--method", help="method used")
    add_parser.add_argument("-o", "--offline", action="store_true", help="was offline")

    # get command
    get_parser = subparsers.add_parser("get", help="Get by code")
    get_parser.add_argument("code", help="code to get")

    # replace command
    replace_parser = subparsers.add_parser("replace", help="String replacement")
    replace_parser.add_argument("original", help="original string")
    replace_parser.add_argument("to_replace", help="string to replace with")
    replace_parser.add_argument("replacement", help="replacement string")

    # misc commands
    clear_parser = subparsers.add_parser("clear", help="Clear history")
    len_parser = subparsers.add_parser("len", help="Get length of history")

    args = parser.parse_args()

    if args.command == "add":
        add(args.content, method=args.method, offline=args.offline)
    elif args.command == "get":
        get(args.code)
    elif args.command == "replace":
        print(args.original.replace(args.to_replace, args.replacement))
    elif args.command == "clear":
        clear()
    elif args.command == "len":
        print(length())


def add(content, method=None, offline=False):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    row = [content, timestamp, method if method else "", "1" if offline else "0"]

    with open(HISTORY_FILE, "a", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_MINIMAL)
        writer.writerow(row)

    update_meta(lambda m: setattr(m, 'count', m.count + 1))


def get(code):
    try:
        command = GetCommand.from_code(code)
    except ValueError as e:
        print(e, file=sys.stderr)
        return

    line = get_line(command.index)
    if not line:
        print("Not found")
        return

    if command.get_time:
        print(line[1])
    else:
        print(line[0])


def clear():
    if os.path.exists(HISTORY_FILE):
        os.remove(HISTORY_FILE)

    update_meta(lambda meta: setattr(meta, 'count', 0))


def length() -> int:
    if not os.path.exists(HISTORY_FILE):
        return 0

    return get_meta().count


# =================================== UTILS ================================== #


def get_line(line_number) -> list[str] | None:
    with open(HISTORY_FILE) as f:
        lines = f.readlines()
        if line_number >= len(lines): return None

    line = lines[line_number].strip()
    return next(csv.reader([line], quoting=csv.QUOTE_MINIMAL))


def get_meta() -> Meta:
    if not os.path.exists(METADATA_FILE):
        return Meta()

    with open(METADATA_FILE) as f:
        data = json.load(f)
        return Meta(**data)


def save_meta(meta: Meta):
    with open(METADATA_FILE, "w") as f:
        json.dump(meta.__dict__, f)


def update_meta(updater):
    meta = get_meta()
    updater(meta)
    save_meta(meta)


# =================================== START ================================== #

if __name__ == "__main__":
    main()
