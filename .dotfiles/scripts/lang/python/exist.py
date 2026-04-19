'''
# README
This is my read-only interface to the api provided by exist.io

# TODO:
- Clean up
- Better error handling
- Right way of paging for all methods
- Help menu
'''

# -------------------------- IMPORTS ------------------------- #

import requests
import os
import sys
import json
from datetime import datetime, time, timedelta
from typing import Any
import argparse

# ------------------------- VARIABLES ------------------------ #

EXIST_TOKEN_READ = os.getenv("EXIST_TOKEN_READ")
if EXIST_TOKEN_READ is None:
    print("EXIST_TOKEN environment variable not set.")
    exit(1)

HEADERS = {'Authorization': f'Token {EXIST_TOKEN_READ}'}

count_aliases = ['len', 'length', 'amt']

# ------------------------- PUBLIC FUNCTIONS ------------------------ #


def main():
    parser = argparse.ArgumentParser()

    if sys.argv[1] in ["list", "plainlist", "corr", *count_aliases, "count"]:
        subparsers = parser.add_subparsers(dest="command")

        list_parser = subparsers.add_parser("list")
        list_parser.add_argument("groups", nargs="?", default="")

        plainlist_parser = subparsers.add_parser("plainlist")
        plainlist_parser.add_argument("groups", nargs="?", default="")

        corr_parser = subparsers.add_parser("corr")
        corr_parser.add_argument("attrs", nargs="+")
        corr_parser.add_argument("-u", "--uncertain", action="store_true")

        count_parser = subparsers.add_parser("count", aliases=count_aliases)
        count_parser.add_argument("attr", nargs=1, type=str)
        count_parser.set_defaults(func=lambda args: get_count(args.attr[0]))

        args = parser.parse_args()

        if args.command == "list":
            return sorted(get_attributes(groups=args.groups))

        elif args.command == "plainlist":
            attributes = sorted(get_attributes(groups=args.groups))
            print("\n".join(attributes))

        elif args.command == "corr":
            return get_correlations(args.attrs, uncertain=args.uncertain)

        elif hasattr(args, "func"):
            return args.func(args)

    else:

        parser.add_argument(
            "attr",
            nargs=1,
            type=str,
        )
        parser.add_argument("days", nargs="?", type=int, default=7)

        parser.add_argument("-u", "--until", type=str, default=None)
        parser.add_argument("--nonull", action="store_true")
        parser.add_argument("--positive", action="store_true")

        args = parser.parse_args()

        if not args.attr:
            parser.error("attr is required unless using a subcommand")

        result = {
            # "timestamp": datetime.now().isoformat(timespec="minutes"),
            **get_values(args.attr, args.days, args.until),
        }

        if args.nonull:
            result = {k: v for k, v in result.items() if v is not None}

        if args.positive:
            result = {k: v for k, v in result.items() if v is not None and v > 0}

        return result


# ------------------------- ABILITIES ------------------------ #


def get_attributes(results=[], url='https://exist.io/api/2/attributes/', groups='') -> list:
    params = {
        'limit': 100,
        'groups': groups,
    }

    response = requests.get(url, params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        exit(1)

    response_data = response.json()
    results = response_data['results']

    names = [result['name'] for result in results]

    next = response_data['next']
    if next is not None:
        names += get_attributes(results, next, groups)

    return names


def get_values(attr: str, days: int, date_max_input: None | datetime | str = None, url=None) -> dict:
    ''' NOTE - Used by env-tracker'''

    if isinstance(date_max_input, datetime):
        date_max = date_max_input
    if _is_valid_date_str(date_max_input):
        date_max = datetime.strptime(date_max_input, '%Y-%m-%d')
    elif is_valid_int(date_max_input):
        days_before = int(date_max_input)
        date_max = (datetime.now() - timedelta(days=days_before))
    else:
        date_max = datetime.now()

    try:
        returned = _fetch_attribute_values(attr, days, date_max.strftime('%Y-%m-%d'), url=url)
        if not returned: return {}

        next = returned.get('next')
        if next is None:
            if returned['total_count'] < days:
                print(f"Only {returned['total_count']} values found.", file=sys.stderr)
            return returned['results']
        else:
            next_page = get_values(attr, days - 100, date_max_input=date_max, url=next)
            return {**returned['results'], **next_page}
    except KeyError as e:
        print(f"KeyError: {e}")
        exit(1)


def get_count(attr: str) -> int:
    return _fetch_attribute_values(attr, None, None)['total_count']


def get_correlations(attrs: list[Any], uncertain: bool = False) -> list:
    keys = [
        'attribute2',
        'value',
        'second_person',
        'offset',
        'stars',
        'period',
    ]
    results = []

    if not attrs:
        attrs.append(None)
        keys.insert(0, 'attribute')

    if len(attrs) > 1:
        keys.insert(0, 'attribute')

    for attr in attrs:
        results.extend(_fetch_attribute_correlations(attr, uncertain))

    for attr in attrs:
        results = [v for v in results if v['attribute2'] != attr]

    results = sorted(results, key=lambda x: x['value'], reverse=True)
    return [{key: d[key] for key in keys if key in d} for d in results]


# ------------------------- FETCH FUNCTIONS ------------------------ #


def _fetch_attribute_correlations(attr: str | None, uncertain: bool) -> list:
    params = {
        'attribute': attr,
        'confident': True,
        'latest': attr is None,
    }
    response = requests.get(f'https://exist.io/api/2/correlations/', params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        print(response.text)
        exit(1)

    response_data = response.json()
    results = response_data['results']

    # Filters
    results = [result for result in results if result['attribute2'] != attr]
    results = [result for result in results if result['attribute2'] != None]

    if not uncertain:
        results = [result for result in results if result['stars'] == 5]

    return results


def _fetch_attribute_values(attr: str, days: int | None, date_max: str | None = None, url=None) -> dict:
    if days and days < 1: return {}

    if url is None:
        url = 'https://exist.io/api/2/attributes/values/'
        params = {'limit': days, 'date_max': date_max, 'attribute': attr}
    else:
        params = None

    response = requests.get(url, params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        exit(1)

    response_data = response.json()
    return {
        'total_count': response_data['count'],
        'next': response_data['next'],
        'results': {
            value['date']: value['value']
            for value in response_data['results'][:days]
        }
    }


# ---------------------- HELPER METHODS ---------------------- #


def _is_valid_date_str(date: str | None | datetime) -> bool:
    if not isinstance(date, str):
        return False

    try:
        datetime.strptime(date, '%Y-%m-%d')
        return True
    except (ValueError, TypeError):
        return False


def is_valid_int(value: str | None | datetime) -> bool:
    if value is None:
        return False

    if isinstance(value, datetime):
        return False

    try:
        int(value)
        return True
    except (ValueError, TypeError):
        return False


# --------------------------- START -------------------------- #

if __name__ == "__main__":
    result = main()

    if result:
        print(json.dumps(result, indent=2), end="")
