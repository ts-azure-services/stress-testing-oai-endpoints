#!/bin/bash

# Sample API_ENDPOINT format for APIM (exclude openai suffix): "https://apim187904087.azure-api.net/load-balancing"

VAR_FILE="./variables.env"

# Check if the file exists
if [ -f "$VAR_FILE" ]; then
    source $VAR_FILE
else
    echo "Variables file does not exist. Run "make variables-init" to create the structure and then populate values."
    exit 1
fi

model="gpt-4o"
URL="${APIM_ENDPOINT}/openai/deployments/${model}/chat/completions?api-version=${API_VERSION}"

# input="Should pineapples be on pizza?"
input=$1
random_number=$RANDOM
output_file="./with-apim/results/results$random_number.log"
error_file="./with-apim/results/error$random_number.log"

# Define the request payload
PAYLOAD=$(jq -n --arg model "$model" --arg input "$input" '{
  model: $model,
    messages: [{"role": "user", "content": $input}]
    }')

# Make the POST request and save the result to a file
result=$(curl -v -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "api-key: $APIM_KEY" \
     -d "$PAYLOAD"
   )

# Check if the request was successful
if [ $? -eq 0 ]; then
  # Log the input and result to the output file
  json_output=$(jq -n --arg input "$input" --argjson result "$result" '{input: $input, result: $result}')
  echo "$json_output" >> "$output_file"
else
  # Log the input to the error file
  echo "$input" >> "$error_file"
fi
