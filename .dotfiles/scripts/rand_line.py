import argparse
import random
import os

# Set up argument parsing
parser = argparse.ArgumentParser(
    description="Get a random line from a specified file.")
parser.add_argument('file', type=str, help="Path to the file")

args = parser.parse_args()
file_path = args.file

# Check if the file exists
if os.path.isfile(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        if lines:
            random_line = random.choice(
                lines).strip()  # Strip removes newline characters

            if len(random_line) > 0:
                print(random_line, end='', flush=True)
            else:
                print("<Empty line>")
        else:
            print("The file is empty.")
else:
    print(f"The file '{file_path}' does not exist or is not a valid file.")
