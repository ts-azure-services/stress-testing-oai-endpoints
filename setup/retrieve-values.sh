#!/bin/bash

# Get the subscription id
source ./sub.env
subscriptionId=$SUBSCRIPTION_ID

# Assumes that within this resource group, there is one APIM instance, and 2 OAI endpoints
resourceGroup=$1

# Get the APIM details
apimInstance=$(az apim list -g $resourceGroup --query "[0].name" -o tsv)
apimEndpoint=$(az apim show --name $apimInstance --resource-group $resourceGroup --query "gatewayUrl" -o tsv)
id="/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.ApiManagement/service/$apimInstance/subscriptions/openai-subscription"
keys=$(az rest --method post --url "$id/listSecrets?api-version=2021-08-01" --query "{primaryKey:primaryKey, secondaryKey:secondaryKey}" -o tsv)
apimKey=$(echo "$keys" | cut -f1)


# Get the OAI endpoint variables
oai=$(az cognitiveservices account list -g $resourceGroup --query "[?kind=='OpenAI'][].name" -o tsv | sort)

# Split the output into an array using newline as the delimiter
IFS=$'\n' read -r -d '' -a names <<< "$oai"

# Assign the values to variables
oaiName1=${names[0]}
oaiName2=${names[1]}

# Get the OpenAI endpoint
openEndpoint1=$(az cognitiveservices account show --name $oaiName1 --resource-group $resourceGroup --query "properties.endpoint" -o tsv)
openEndpoint2=$(az cognitiveservices account show --name $oaiName2 --resource-group $resourceGroup --query "properties.endpoint" -o tsv)

# Get the keys for the OpenAI service
openKey1=$(az cognitiveservices account keys list --name $oaiName1 --resource-group $resourceGroup --query "key1" -o tsv)
openKey2=$(az cognitiveservices account keys list --name $oaiName2 --resource-group $resourceGroup --query "key1" -o tsv)


printf "${grn}WRITING OUT ENVIRONMENT VARIABLES...${end}\n"
configFile='variables.env'
printf "SUBSCRIPTION_ID=$subscriptionId\n"> $configFile
printf "RESOURCE_GROUP=$resourceGroup\n">> $configFile
printf "APIM_NAME=$apimInstance\n">> $configFile
printf "APIM_ENDPOINT=$apimEndpoint\n">> $configFile
printf "APIM_KEY=$apimKey\n">> $configFile
printf "API_ENDPOINT=$openEndpoint1\n">> $configFile
printf "API_KEY=$openKey1\n">> $configFile
printf "SECOND_ENDPOINT=$openEndpoint2\n">> $configFile
printf "SECOND_KEY=$openKey2\n">> $configFile
printf "API_VERSION=2024-10-21\n">> $configFile
