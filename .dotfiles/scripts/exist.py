'''
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
import math

# ------------------------- VARIABLES ------------------------ #

EXIST_TOKEN_READ = os.getenv("EXIST_TOKEN_READ")
if EXIST_TOKEN_READ is None:
    print("EXIST_TOKEN environment variable not set.")
    exit(1)

HEADERS = {'Authorization': f'Token {EXIST_TOKEN_READ}'}

# ------------------------- PUBLIC FUNCTIONS ------------------------ #


def main() -> any:
    args_len = len(sys.argv)

    attr = sys.argv[1]

    if attr in ['l', 'list']:
        groups = sys.argv[2] if args_len >= 3 else ''

        return sorted(list_attributes(groups=groups))

    if args_len >= 3:
        if sys.argv[2].isnumeric():
            days = int(sys.argv[2])
        elif sys.argv[2] in ['count', 'cnt', 'len']:
            return count(attr)
        elif sys.argv[2] in ['correlations', 'corr']:
            return correlations(attr)
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


def values(attr: str, days: int, date_max_input: int | None = None) -> dict:

    if _is_valid_date(date_max_input):
        date_max = datetime.strptime(date_max_input, '%Y-%m-%d')
    elif is_valid_int(date_max_input):
        days_before = int(date_max_input)
        date_max = (datetime.now() - timedelta(days=days_before))
    else:
        date_max = datetime.now()

    result = {}
    iters = math.floor(days / 100)

    try:
        for _ in range(iters):
            returned = _fetch_attribute_values(attr, 100, date_max.strftime('%Y-%m-%d'))
            result.update(returned['results'])
            date_max -= timedelta(days=100)

        if days % 100 != 0:
            returned = _fetch_attribute_values(attr, days % 100, date_max.strftime('%Y-%m-%d'))
            result.update(returned['results'])

        return result
    except KeyError as e:
        print(f"KeyError: {e}")
        print(returned)
        exit(1)


def count(attr: str) -> int:
    return _fetch_attribute_values(attr, None, None)['total_count']


def correlations(attr: str) -> list_attributes:
    results = _fetch_attribute_correlations(attr)
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


# ------------------------- PRIVATE FUNCTIONS ------------------------ #


def _fetch_attribute_correlations(attr: str) -> list_attributes:
    params = {
        'attribute': attr,
        'confident': True,
    }
    response = requests.get(f'https://exist.io/api/2/correlations/', params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        print(response.text)
        exit(1)

    response_data = response.json()
    results = response_data['results']

    # Filters
    results = [result for result in results if result['stars'] >= 4]
    results = [result for result in results if result['attribute2'] != attr]
    results = [result for result in results if result['attribute2'] != None]
    return results


def _fetch_attribute_values(attr: str, days: int | None, date_max: str = None) -> dict:
    if days == 0: return {}

    params = {'limit': days, 'date_max': date_max, 'attribute': attr}
    response = requests.get('https://exist.io/api/2/attributes/values/', params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        exit(1)

    response_data = response.json()
    return {
        'total_count': response_data['count'],
        'results': {
            value['date']: value['value']
            for value in response_data['results']
        }
    }


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
