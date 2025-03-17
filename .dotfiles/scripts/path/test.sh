#!/bin/zsh

# Function to get a parameter using 'is param 1'
get_param() {
    is $1 1 | jq '.[] // 0'
}

# Extract parameters
day_length=$(get_param "day_length")
cloud_cover=$(get_param "weather_cloud_cover")
precipitation=$(get_param "weather_precipitation")
humidity=$(get_param "weather_humidity")

# Compute brightness proxy
brightness=$(echo "$day_length * (1 - 0.8 * $cloud_cover) * (1 - 0.5 * $precipitation) * (1 - 0.3 * $humidity)" | bc -l)

# Output result
echo "Estimated Outdoor Brightness: $brightness"
