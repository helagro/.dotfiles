import sys

map = {}
n = int(sys.argv[1])

for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue

    text = line.split(' - ')[-1]

    if text in map:
        map[text] += 1
    else:
        map[text] = 1

for key in map:
    if map[key] < n:
        continue

    print(f"{key} - {map[key]}")
