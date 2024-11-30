#!/bin/bash

VAR_FILE="./variables.env"

# Check if the file exists
if [ -f "$VAR_FILE" ]; then
    source $VAR_FILE
else
    echo "Variables file does not exist. Run "make variables-init" to create the structure and then populate values."
    exit 1
fi

# Load variables
apim_name=$APIM_NAME
location=$1

# # To get a list of all APIM instances
# az apim deletedservice list --subscription $subscriptionID
result=$(az apim deletedservice purge -n $APIM_NAME -l $location)

# Check if the request was successful
if [ $? -eq 0 ]; then
  echo "Soft purge completed."
  # echo "Result: $result"
else
  echo "Failed to soft-purge."
  # printf "Error message: %s\n" "$result"
  exit 1
fi
