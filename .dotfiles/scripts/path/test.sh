my_array=("apple" "banana" "cherry")
joined_string="${(j:,:)my_array}"
echo "$joined_string"
