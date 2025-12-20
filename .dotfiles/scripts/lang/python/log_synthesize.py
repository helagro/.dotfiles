import sys

map = {}
lookup = {}
n = int(sys.argv[1])

for line in sys.stdin:
    line = line.rstrip("\n")
    if not line.strip():
        continue

    text = line.split(' - ')[-1]
    searchTxt = text.split('**')[0].strip()

    if text != searchTxt:
        if searchTxt in lookup:
            lookup[searchTxt].append(text)
        else:
            lookup[searchTxt] = [text]

    if searchTxt in map:
        map[searchTxt] += 1
    else:
        map[searchTxt] = 1

for key in map:
    if map[key] < n:
        continue

    if key in lookup:
        for variant in lookup[key]:
            print(variant)
    else:
        print(f"{key} - {map[key]}")
