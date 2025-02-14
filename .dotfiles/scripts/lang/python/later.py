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
        handle_line(line.strip())

        with open(FILE_PATH, "w") as file:
            file.writelines(lines[(i + 1):])


def handle_line(line):
    if not line:
        return

    action = input(f'"{line}" :', )
    if action == 'y':
        subprocess.run(["zsh", "-i", "-c", f"{line}"], stdout=sys.stdout, stderr=sys.stderr, text=True, shell=False)
    elif action == 'n':
        return
    elif action == 'c':
        os.system(f'printf "{line}" | pbcopy')
    elif action == 'q':
        exit(0)
    else:
        print('Invalid input - enter (y, n, c or q)')
        handle_line(line)


if __name__ == '__main__':
    if len(sys.argv) > 1:
        command = ' '.join(sys.argv[1:])

        if command == 'stdin':
            if not sys.stdin.isatty():
                command = sys.stdin.read()
                if command: command = command.strip()

            elif sys.stdin.isatty():
                print('Warn - stdin is not a tty')

        add_to_later(command)

    else:
        run_later()
