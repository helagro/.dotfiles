import sys
import json
from datetime import datetime


def read_input():
    input_data = sys.stdin.read()

    try:
        data = json.loads(input_data)
    except json.JSONDecodeError:
        print("Invalid JSON input")
        sys.exit(1)

    if isinstance(data, dict):
        return data
    else:
        print("Invalid input")
        sys.exit(1)


def process_dict(data, operation):
    res = {}

    for date, value in data.items():
        week = week_code(date)

        if value is None:
            continue

        if week in res:
            res[week] += [value]
        else:
            res[week] = [value]

    if operation == "avg":
        res = {week: round(sum(values) / len(values), 2) for week, values in res.items()}
    elif operation == "sum":
        res = {week: sum(values) for week, values in res.items()}
    else:
        raise ValueError("Invalid operation")

    print(json.dumps(res, indent=2))


def week_code(date_str):
    date = datetime.strptime(date_str, "%Y-%m-%d")
    iso_week = date.isocalendar().week

    return f"{date.strftime('%Y')}-W{iso_week}"


if __name__ == "__main__":
    operation = sys.argv[1] if len(sys.argv) >= 2 else "avg"

    input = read_input()
    process_dict(input, operation)
