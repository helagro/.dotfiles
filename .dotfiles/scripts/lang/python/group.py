import sys
import json
from datetime import datetime
from enum import Enum

# =========================== ENUMS =========================== #


class Grouping(Enum):
    WEEK = "w"
    MONTH = "m"
    YEAR = "y"


class Operation(Enum):
    AVG = ["avg", "mean"]
    SUM = "sum"


# =========================== FUNCTIONS =========================== #


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


def process_dict(data, operation: str, grouping: str):
    res = {}
    group_fun_ptr = None

    if grouping == Grouping.WEEK.value:
        group_fun_ptr = week_code
    elif grouping == Grouping.MONTH.value:
        group_fun_ptr = month_code
    elif grouping == Grouping.YEAR.value:
        group_fun_ptr = year_code
    else:
        raise ValueError("Invalid grouping")

    for date, value in data.items():
        code = group_fun_ptr(date)

        if value is None:
            continue

        if code in res:
            res[code] += [value]
        else:
            res[code] = [value]

    if operation in Operation.AVG.value:
        res = {week: round(sum(values) / len(values), 2) for week, values in res.items()}
    elif operation == Operation.SUM.value:
        res = {week: sum(values) for week, values in res.items()}
    else:
        raise ValueError("Invalid operation")

    print(json.dumps(res, indent=2))


def week_code(date_str):
    date = datetime.strptime(date_str, "%Y-%m-%d")
    iso_week = date.isocalendar().week

    return f"{date.strftime('%Y')}-W{iso_week}"


def month_code(date_str):
    date = datetime.strptime(date_str, "%Y-%m-%d")
    return date.strftime('%Y-%m')


def year_code(date_str):
    date = datetime.strptime(date_str, "%Y-%m-%d")
    return date.strftime('%Y')


# =========================== START ========================== #

if __name__ == "__main__":
    grouping = Grouping.WEEK.value
    operation = Operation.AVG.value[1]

    if len(sys.argv) >= 2:
        grouping = sys.argv[1][0].lower()

    if len(sys.argv) >= 3:
        operation = sys.argv[2]

    input = read_input()
    process_dict(input, operation, grouping)
