import sys
import argparse
import re
import json


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-f",
        help="Tag to filter by, including",
        type=str,
        nargs="+",
        action="append",
    )

    parser.add_argument(
        "-F",
        help="Tag to filter by in, excluding",
        type=str,
        nargs="+",
        action="append",
    )

    parser.add_argument(
        "-l",
        "--list",
        help="List all tags",
        action="store_true",
    )

    parser.add_argument(
        "-r",
        "--raw",
        help="Print raw lines",
        action="store_true",
    )

    return parser.parse_args()


def main(input, args):
    lines = input.splitlines()
    found_tags = set()

    for i, line in enumerate(lines):
        if re.match(r"^#+ Checklist", line):
            hashtags_count = line.count("#")
            break

    if i == -1:
        print("No checklist found")
        return

    for i in range(i + 1, len(lines)):
        line = lines[i]

        if re.match(r".*\^\w+.*", line):
            found_tags.add(re.findall(r"\^\w+", line)[0][1:])

        if args.list:
            continue

        if line.startswith("#") and line.count("#") <= hashtags_count:
            break

        if not excluded_by_tags(line, args.F) and included_by_tags(line, args.f):
            print_line(line, args.raw)

    tags_str = json.dumps(list(found_tags))
    if args.list:
        print(tags_str)
    else:
        print(f'<!-- {tags_str} -->')


def excluded_by_tags(line, tags):
    if not tags:
        return False

    for tag_arr in tags:
        for tag in tag_arr:
            if f"^{tag}" in line:
                return True

    return False


def included_by_tags(line, tags):
    if not tags:
        return True

    for tag_arr in tags:
        for tag in tag_arr:
            if f"^{tag}" in line:
                return True

    return False


def print_line(line, print_raw=False):
    if not print_raw:
        line = re.sub(r'<!--.*?-->\n?', '', line, flags=re.DOTALL)

    print(line)


if __name__ == "__main__":
    stdin = sys.stdin.read()
    args = parse_args()
    main(stdin, args)
