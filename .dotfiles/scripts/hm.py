import sys
import json


def process_dict(data):
    for date, minutes in data.items():
        time_str = hm(minutes) if minutes is not None else "Null"
        print(f"{date}: {time_str}")


def hm(mins):
    mins = round(mins)
    hours = mins // 60
    minutes = mins % 60
    return f"{hours:02}:{minutes:02}"


def process_input():
    # Read JSON input from stdin
    input_data = sys.stdin.read()

    # Parse the input data as JSON
    try:
        data = json.loads(input_data)
    except json.JSONDecodeError:
        print("Invalid JSON input")
        return

    if isinstance(data, dict):
        process_dict(data)
    elif isinstance(data, (int, float)):
        print(hm(data))
    else:
        print("Invalid input")


if __name__ == "__main__":
    process_input()