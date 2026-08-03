#!/bin/zsh 

# =============================== GET LOCATION =============================== #

response=$(curl -s http://ip-api.com/json/)
lat=$(echo $response | jq '.lat')
lon=$(echo $response | jq '.lon')

# ============================== GET POLLEN DATA ============================= #

# pollen_response=$(cat /Users/h/.dotfiles/tmp/tmp.json)
pollen_response=$(curl -sX GET "https://pollen.googleapis.com/v1/forecast:lookup?location.latitude=$lat&location.longitude=$lon&days=1" \
  -H "Authorization: Bearer $(gcloud auth application-default print-access-token)"  \
  -H "x-goog-user-project: sheets-409712")

pollen_type_info=$(echo $pollen_response | jq '.dailyInfo[0].pollenTypeInfo[]')

# =================================== TRACK ================================== #

track_command=""

grass_pollen_info=$(echo $pollen_response | jq '.dailyInfo[0].pollenTypeInfo[] | select(.code=="GRASS")')
if [[ -n $grass_pollen_info ]]; then
    grass_pollen_value=$(echo "$grass_pollen_info" | jq '.indexInfo.value')

    if [[ $grass_pollen_value != 'null' ]]; then
        track_command+="pollen_grass $grass_pollen_value ; "
    fi
fi

tree_pollen_info=$(echo $pollen_response | jq '.dailyInfo[0].pollenTypeInfo[] | select(.code=="TREE")')
if [[ -n $tree_pollen_info ]]; then
    tree_pollen_value=$(echo "$tree_pollen_info" | jq '.indexInfo.value')
    
    if [[ $tree_pollen_value != 'null' ]]; then
        track_command+="pollen_tree $tree_pollen_value ; "
    fi
fi

oak_pollen_info=$(echo $pollen_response | jq '.dailyInfo[0].plantInfo[] | select(.code == "OAK")')
if [[ -n $oak_pollen_info ]]; then
    oak_pollen_value=$(echo "$oak_pollen_info" | jq '.indexInfo.value')
    
    if [[ $oak_pollen_value != 'null' ]]; then
        track_command+="pollen_oak $oak_pollen_value ; "
    fi
fi

birch_pollen_info=$(echo $pollen_response | jq '.dailyInfo[0].plantInfo[] | select(.code == "BIRCH")')
if [[ -n $birch_pollen_info ]]; then
    birch_pollen_value=$(echo "$birch_pollen_info" | jq '.indexInfo.value')

    if [[ $birch_pollen_value != 'null' ]]; then
        track_command+="pollen_birch $birch_pollen_value ; "
    fi
fi

A75H="$A75H" a.sh "$track_command"
