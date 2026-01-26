import sys
import json


def hm_to_mins(hm: str) -> None:
    try:
        hours, minutes = hm.split(':')
        print(int(hours) * 60 + int(minutes))
    except ValueError:
        raise ValueError("Invalid input")


def process_dict(data):
    res = {}

    for date, minutes in data.items():
        if minutes is None:
            res[date] = None
        elif isinstance(minutes, (int, float)):
            res[date] = hm(minutes)
        else:
            res[date] = minutes

    print(json.dumps(res, indent=2))


def hm(mins):
    mins = round(mins)
    hours = mins // 60
    minutes = mins % 60
    return f"{hours:02}:{minutes:02}"


if __name__ == "__main__":
    if len(sys.argv) > 1:
        input_data = " ".join(sys.argv[1:])  # Join all arguments as a single string
    else:
        input_data = sys.stdin.read()

    if ':' in input_data and not input_data.startswith('{'):
        hm_to_mins(input_data)
    else:
        try:
            data = json.loads(input_data)
        except json.JSONDecodeError:
            print("Invalid JSON input")
            sys.exit(1)

        if isinstance(data, dict):
            process_dict(data)
        elif isinstance(data, (int, float)):
            print(hm(data))
        else:
            print("Invalid input")
