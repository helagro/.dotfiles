import sys
import json

def hm(mins):
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

    # Process each key-value pair
    for date, minutes in data.items():
        time_str = hm(minutes) if minutes is not None else "Null"
        print(f"{date}: {time_str}")

if __name__ == "__main__":
    process_input()