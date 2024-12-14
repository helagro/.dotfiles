import requests
import os
import sys
import json
from datetime import datetime, timedelta
import math

URL = 'https://exist.io/api/2/attributes/values/'
headers = {'Authorization': f'Token {os.getenv("EXIST_TOKEN_READ")}'}


def fetch_attribute_values(attr: str, days: int, date_max: str = None) -> dict:
    if days == 0: return {}

    params = {'limit': days, 'date_max': date_max, 'attribute': attr}
    response = requests.get(URL, params=params, headers=headers)

    if not response.ok:
        return '{ "error": "Could not find data" }'

    response_data = response.json()
    return {value['date']: value['value'] for value in response_data['results']}


def is_valid_date(date: str) -> bool:
    try:
        datetime.strptime(date, '%Y-%m-%d')
        return True
    except ValueError:
        return False


def is_valid_int(value: str) -> bool:
    try:
        int(value)
        return True
    except ValueError:
        return False


if __name__ == "__main__":
    args_len = len(sys.argv)

    attr = sys.argv[1]
    days = int(sys.argv[2]) if args_len >= 3 else 7
    date_max_input = sys.argv[3] if args_len >= 4 else None

    if is_valid_date(date_max_input):
        date_max = datetime.strptime(date_max_input, '%Y-%m-%d')
    elif is_valid_int(date_max_input):
        days_before = int(date_max_input)
        date_max = (datetime.now() - timedelta(days=days_before))

    result = {}
    iters = math.floor(days / 100)

    for i in range(iters):
        result.update(fetch_attribute_values(attr, 100, date_max.strftime('%Y-%m-%d')))
        date_max -= timedelta(days=100)

    result.update(fetch_attribute_values(attr, days % 100, date_max.strftime('%Y-%m-%d')))
    print(json.dumps(result, indent=2), end="")
