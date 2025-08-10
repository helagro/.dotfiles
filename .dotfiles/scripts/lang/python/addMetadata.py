import sys
import json
import platform


def main():
    if len(sys.argv) < 2:
        print("Usage: python script.py <input_string>")
        sys.exit(1)

    input_str = sys.argv[1]
    output = {"content": input_str, "origin": "a.sh", "platform": platform.system()}
    print(json.dumps(output, separators=(', ', ': ')), )


if __name__ == "__main__":
    main()
