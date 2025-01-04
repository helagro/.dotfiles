import sys
import json


def main():
    # Ensure an argument is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py <arg>")
        sys.exit(1)

    arg = sys.argv[1]

    # Read JSON from stdin
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        print("Invalid JSON input")
        sys.exit(1)

    # Process and print the output
    if len(data.items()) > 100:
        print("Gonna cook the server...")
        sys.exit(1)

    for date, value in data.items():
        print(f"{date} {arg} {value} s")


if __name__ == "__main__":
    main()
