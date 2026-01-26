import sys
import os
import subprocess

FILE_PATH = f'{os.getenv("HOME")}/.dotfiles/tmp/later.txt'


def add_to_later(command):
    command = command.rstrip("\n")

    try:
        with open(FILE_PATH, "r") as file:
            existing = {line.rstrip("\n") for line in file}
    except FileNotFoundError:
        existing = set()

    if command not in existing:
        with open(FILE_PATH, "a") as file:
            file.write(f"{command}\n")


def run_later():
    lines_to_save = []

    with open(FILE_PATH, "r") as file:
        line = file.readline()
        while line:
            text = line.strip()
            save_line = handle_line(text)

            if save_line:
                lines_to_save.append(text)

            line = file.readline()

    with open(FILE_PATH, "w") as file:
        file.write('')
        for line in lines_to_save:
            file.write(f'{line}\n')


def handle_line(line):
    ''' Handles line. Returns if should save line '''
    if not line:
        return False

    should_save = False
    action = input(f'"{line}" :', )

    if 's' in action:
        should_save = True

    if 'y' in action:
        subprocess.run(["zsh", "-i", "-c", f"{line}"], stdout=sys.stdout, stderr=sys.stderr, text=True, shell=False)
    elif 'n' in action:
        pass
    elif action == 'c':
        os.system(f'printf "{line}" | pbcopy')
    elif action == 'q':
        exit(0)
    elif not should_save:
        print('Invalid input - enter (y, n, c, s or q)')
        handle_line(line)

    return should_save


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
