'''
# README
This is my read-only interface to the api provided by exist.io

# TODO:
- Clean up
- Export
- Better error handling
- Right way of paging for all methods
- Help menu
'''

# -------------------------- IMPORTS ------------------------- #

import requests
import os
import sys
import json
from datetime import datetime, timedelta

# ------------------------- VARIABLES ------------------------ #

EXIST_TOKEN_READ = os.getenv("EXIST_TOKEN_READ")
if EXIST_TOKEN_READ is None:
    print("EXIST_TOKEN environment variable not set.")
    exit(1)

HEADERS = {'Authorization': f'Token {EXIST_TOKEN_READ}'}

# ------------------------- PUBLIC FUNCTIONS ------------------------ #


def main():
    args_len = len(sys.argv)

    attr = sys.argv[1]

    if attr in ['l', 'list']:
        groups = sys.argv[2] if args_len >= 3 else ''

        return sorted(list_attributes(groups=groups))

    if sys.argv[-1] in ['correlations', 'corr']:
        return correlations(sys.argv[1:-1])

    if args_len >= 3:
        if sys.argv[2].isnumeric():
            days = int(sys.argv[2])
        elif sys.argv[2] in ['count', 'cnt', 'len']:
            return count(attr)
    else:
        days = 7

    date_max_input = sys.argv[3] if args_len >= 4 else None
    return values(attr, days, date_max_input)


# ------------------------- ABILITIES ------------------------ #


def list_attributes(results=[], url='https://exist.io/api/2/attributes/', groups='') -> list:
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
        names += list_attributes(results, next, groups)

    return names


def values(attr: str, days: int, date_max_input=None, url=None) -> dict:
    ''' NOTE - Used by env-tracker'''

    if _is_valid_date(date_max_input):
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
            next_page = values(attr, days - 100, date_max_input=date_max, url=next)
            return {**returned['results'], **next_page}
    except KeyError as e:
        print(f"KeyError: {e}")
        print(returned)
        exit(1)


def count(attr: str) -> int:
    return _fetch_attribute_values(attr, None, None)['total_count']


def correlations(attrs: list[str | None]) -> list:
    results = []
    if not attrs:
        attrs.append(None)

    for attr in attrs:
        results.extend(_fetch_attribute_correlations(attr))
        results = sorted(results, key=lambda x: x['value'], reverse=True)

    keys = [
        'attribute2',
        'value',
        'second_person',
        'offset',
        'stars',
        'period',
    ]

    return [{key: d[key] for key in keys if key in d} for d in results]


# ------------------------- FETCH FUNCTIONS ------------------------ #


def _fetch_attribute_correlations(attr: str | None) -> list:
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
    results = [result for result in results if result['stars'] >= 5]
    results = [result for result in results if result['attribute2'] != attr]
    results = [result for result in results if result['attribute2'] != None]
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


def _is_valid_date(date: str | None) -> bool:
    try:
        datetime.strptime(date, '%Y-%m-%d')
        return True
    except (ValueError, TypeError):
        return False


def is_valid_int(value: str | None) -> bool:
    try:
        int(value)
        return True
    except (ValueError, TypeError):
        return False


# --------------------------- START -------------------------- #

if __name__ == "__main__":
    result = main()
    print(json.dumps(result, indent=2), end="")
