import requests
import os
import sys
import json
from datetime import datetime, timedelta
import math

# ------------------------- VARIABLES ------------------------ #

URL = 'https://exist.io/api/2/attributes/values/'

EXIST_TOKEN_READ = os.getenv("EXIST_TOKEN_READ")
if EXIST_TOKEN_READ is None:
    print("EXIST_TOKEN environment variable not set.")
    exit(1)

HEADERS = {'Authorization': f'Token {EXIST_TOKEN_READ}'}

# ------------------------- PUBLIC FUNCTIONS ------------------------ #


def main(attr: str, days: int, date_max_input: int | None = None) -> dict:

    if _is_valid_date(date_max_input):
        date_max = datetime.strptime(date_max_input, '%Y-%m-%d')
    elif is_valid_int(date_max_input):
        days_before = int(date_max_input)
        date_max = (datetime.now() - timedelta(days=days_before))
    else:
        date_max = datetime.now()

    result = {}
    iters = math.floor(days / 100)

    for _ in range(iters):
        result.update(_fetch_attribute_values(attr, 100, date_max.strftime('%Y-%m-%d')))
        date_max -= timedelta(days=100)

    result.update(_fetch_attribute_values(attr, days % 100, date_max.strftime('%Y-%m-%d')))
    return result


# ------------------------- PRIVATE FUNCTIONS ------------------------ #


def _fetch_attribute_values(attr: str, days: int, date_max: str = None) -> dict:
    if days == 0: return {}

    params = {'limit': days, 'date_max': date_max, 'attribute': attr}
    response = requests.get(URL, params=params, headers=HEADERS)

    if not response.ok:
        print(f"Fetch failed with status code {response.status_code}")
        exit(1)

    response_data = response.json()
    return {value['date']: value['value'] for value in response_data['results']}


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
    args_len = len(sys.argv)

    attr = sys.argv[1]
    days = int(sys.argv[2]) if args_len >= 3 else 7
    date_max_input = sys.argv[3] if args_len >= 4 else None

    result = main(attr, days, date_max_input)
    print(json.dumps(result, indent=2), end="")
