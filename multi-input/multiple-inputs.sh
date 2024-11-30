#!/bin/bash

VAR_FILE="./variables.env"

# Check if the file exists
if [ -f "$VAR_FILE" ]; then
    source $VAR_FILE
else
    echo "Variables file does not exist. Run "make variables-init" to create the structure and then populate values."
    exit 1
fi

# URL=($API_ENDPOINT?api-version=$API_VERSION)
model="gpt-4o"
URL="${API_ENDPOINT}openai/deployments/${model}/chat/completions?api-version=${API_VERSION}"
input=$1
random_number=$RANDOM
output_file="./multi-input/results/results$random_number.log"
error_file="./multi-input/results/error$random_number.log"

# Define the request payload
PAYLOAD=$(jq -n --arg input "$input" '{
  model: "gpt-4o",
    messages: [{"role": "user", "content": $input}]
    }')

# Make the POST request and save the result to a file
result=$(curl -v -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "api-key: $API_KEY" \
     -d "$PAYLOAD"
   )

# Check if the request was successful
if [ $? -eq 0 ]; then
  # # Log the input and result to the output file
  json_output=$(jq -n --arg input "$input" --argjson result "$result" '{input: $input, result: $result}')
  echo "$json_output" >> "$output_file"
else
  # Log the input to the error file
  echo "$input" >> "$error_file"
fi
