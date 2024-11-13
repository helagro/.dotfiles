import sys
import json

def calculate_statistic(json_str, operation):
    # Parse JSON string
    data = json.loads(json_str)
    
    # Ensure values are numeric
    values = list(data.values())
    numeric_values = [v for v in values if isinstance(v, (int, float))]

    if not numeric_values:
        return 0

    if operation == "max":
        return max(numeric_values)
    elif operation == "min":
        return min(numeric_values)
    elif operation == "sum":
        return sum(numeric_values) 
    elif operation == "avg":
        return sum(numeric_values) / len(numeric_values)
    else:
        raise ValueError("Invalid operation")


if __name__ == "__main__":
    operation = sys.argv[1] if len(sys.argv) >= 2 else "avg"
    json_input = sys.stdin.read().strip()

    try:
        result = calculate_statistic(json_input, operation)
        print(f'{result:.2f}' if isinstance(result, float) else result)
    except ValueError as e:
        print(e)