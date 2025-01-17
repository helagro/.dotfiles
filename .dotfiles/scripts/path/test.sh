#!/bin/zsh

input_json=""
read -r -d '' input_json

# Use jq to group by week and calculate weekly averages

echo "$input_json" | jq -r '
    to_entries |
    map(
      .key as $date |
      .value as $value |
      {week: ($date | strptime("%Y-%m-%d") | mktime | gmtime | strftime("%Y-W%W")), value: $value}
    ) |
    group_by(.week) |
    map(
      {week: .[0].week, average: ([.[].value | select(. != null)] | if length == 0 then null else add / length end)}
    ) |
    map({(.week): .average}) |
    add
  ' | bat -pl json
