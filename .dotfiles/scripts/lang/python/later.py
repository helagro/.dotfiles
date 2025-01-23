import sys
import os
import subprocess

FILE_PATH = f'{os.getenv("HOME")}/.dotfiles/tmp/later.txt'


def add_to_later(command):
    with open(FILE_PATH, "a") as file:
        file.write(f'{command}\n')


def run_later():
    with open(FILE_PATH, "r") as file:
        lines = file.readlines()

    for i, line in enumerate(lines):
        if line:
            handle_line(line.strip())

        with open(FILE_PATH, "w") as file:
            file.writelines(lines[(i + 1):])


def handle_line(line):
    action = input(f'"{line}" :', )
    if action == 'y':
        subprocess.run(["zsh", "-i", "-c", f"{line}"], stdout=sys.stdout, stderr=sys.stderr, text=True, shell=False)
    elif action == 'n':
        return
    elif action == 'q':
        exit(0)
    else:
        print('Invalid input - enter (y, n or q)')
        handle_line(line)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        command = ' '.join(sys.argv[1:])

        if command == 'stdin' and not sys.stdin.isatty():
            command = sys.stdin.read()
            if command: command = command.strip()

        add_to_later(command)

    else:
        run_later()
