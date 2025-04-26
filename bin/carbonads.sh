#!/bin/bash

# shellcheck disable=SC2155

CARBONADS_URL="https://srv.carbonads.net"

get_ads() {
    local ID="$1"
    local PLACEMENT="$2"
    curl -sL "$CARBONADS_URL/ads/${ID}.json?segment=placement:${PLACEMENT}&v=true" | jq -r '.ads[0]'
}

hyperlink() {
    echo -e "\e]8;;$1\e\\$2\e]8;;\e\\"
}

normalize() {
    echo -e "$1" | sed -r 's/\x1B\]8;;[^\\]+\\([^\x1B]+)\x1B\]8;;\x1B\\/\1/g; s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g'
}

# Function to print text in an ASCII box
print_box() {
    local content="$1"

    local top_left="╭"
    local top_right="╮"
    local bottom_left="╰"
    local bottom_right="╯"
    local horizontal="─"
    local vertical="│"

    local lines=()
    local longest_line=0

    # Read the text line by line
    while IFS= read -r line; do
        lines+=("$line")

        local normalized_line=$(echo -e "$line" | sed -b 's/\x1b[^m]*m//g')
        local line_lenght=$(echo -en "$normalized_line" | wc -m)

        if [[ "$longest_line" -lt "$line_lenght" ]]; then
            longest_line="$line_lenght"
        fi
    done <<<"$content"

    local width="$longest_line"
    local padding=2
    local total_width=$((width + padding))

    echo -e "$top_left$(printf -- "$horizontal%.0s" $(seq 1 $total_width))$top_right"

    for line in "${lines[@]}"; do
        # local s=$(echo "$line")
        local normalized_line=$(echo -e "$line" | sed -b 's/\x1b[^m]*m//g')
        local line_lenght=$(echo -en "$normalized_line" | wc -m)
        # echo "$total_width"
        # echo "$line_lenght"
        local si="$((total_width - padding - line_lenght + 1))"
        # echo "$si"
        echo -e "$vertical $line\e[0m$(printf '%*s' "$si" ' ')$vertical"
        # echo -e "$vertical $line$(printf "%-.s" "$line")\e[0m $vertical"
    done

    echo -e "$bottom_left$(printf -- "$horizontal%.0s" $(seq 1 $total_width))$bottom_right"
}

# Check if enough arguments are passed
if [ $# -ne 2 ]; then
    echo "Usage: $0 <id> <placement>"
    exit 1
fi

ID="$1"
PLACEMENT="$2"

# Get JSON with advertising
RESPONSE=$(get_ads "$ID" "$PLACEMENT")

# Extract description and link
TEXT=$(echo "$RESPONSE" | jq -r '.description' | fold -w 38 -s)
LINK=$(echo "$RESPONSE" | jq -r '.statlink')
IMAGE=$(echo "$RESPONSE" | jq -r '.smallImage')
CREATIVE_ID=$(echo "$RESPONSE" | jq -r '.creativeid')

temp_image="/tmp/carbonads-$CREATIVE_ID"

touch "$temp_image"

curl -s "$IMAGE" -o "$temp_image"

# Check if there is data
if [ "$TEXT" == "null" ] || [ "$LINK" == "null" ]; then
    echo "Error: Could not get advertising."
    exit 1
fi

image() {
    while IFS= read -r line; do
        local s=$(echo -e "$line" | head -c -2)
        echo -e "$s"
    done <<<"$1"
}

# Output advertising in a box
print_box "$(echo -e "$(image "$(viu -w 40 -b "$temp_image")\n")\n\n$TEXT")"
