import sys
import json

def calculate_average(json_str):
    # Parse JSON string
    data = json.loads(json_str)
    
    # Ensure values are numeric and calculate the average
    values = list(data.values())
    numeric_values = [v for v in values if isinstance(v, (int, float))]

    if not numeric_values:
        return 0

    average = sum(numeric_values) / len(numeric_values)
    return average

if __name__ == "__main__":
    # Read JSON input from stdin
    json_input = sys.stdin.read().strip()
    result = calculate_average(json_input)
    print(f'{result:.2f}')