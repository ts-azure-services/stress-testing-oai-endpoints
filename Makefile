# These scripts assume a working state of the following tools locally: jq, parallel, grep
# TO-DO: Actively test this all in the Cloud Shell

RED = \033[0;31m
NC = \033[0m # No Color
GREEN = \033[0;32m

define log_section
	@printf "\n${GREEN}--> $(1)${NC}\n\n"
endef

deployment_name="deploy24"
resource_group="apim-sampler-234"
location="westus"

venv-setup:
	$(call log_section, Create virtual environment...)
	rm -rf .venv
	python3.11 -m venv .venv
	.venv/bin/python -m pip install --upgrade pip
	.venv/bin/python -m pip install -r ./requirements.txt --quiet

# Note that APIM only soft-deletes as per this article: https://learn.microsoft.com/en-us/azure/api-management/soft-delete
# In these scripts, the same name is re-used based off a specific combination, so you have to purge the soft-delete for the bicep template to work
soft-purge-apim:
	$(call log_section, Soft purge the APIM instance, if not starting from scratch...)
	./setup/soft-purge-apim.sh $(location)

# Github link: https://github.com/Azure/azure-rest-api-specs/tree/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable
# oai_file="https://raw.githubusercontent.com/Azure/azure-rest-api-specs/main/specification/cognitiveservices/data-plane/AzureOpenAI/inference/stable/2024-10-21/inference.json"
setup-apim:
	$(call log_section, Setup Azure resources...)
	az group create --name $(resource_group) --location $(location)
	az deployment group create --name $(deployment_name) --resource-group $(resource_group) --template-file "./setup/create-resources/main.bicep" --parameters "./setup/create-resources/params.json"
	# Consider manually maxing out the OpenAI instances after this step

sub-init:
	$(call log_section, Execute and manually update your subscription id...)
	echo "SUBSCRIPTION_ID=<enter subscription>" > sub.env

variables-init:
	$(call log_section, Capture output variables...)
	rm -rf ./variables.env
	./setup/retrieve-values.sh $(resource_group)

cleanup:
	$(call log_section, Cleanup all result folders...)
	rm -rf ./static-input/results
	rm -rf ./multi-input/results
	rm -rf ./with-apim/results


static:
	$(call log_section, Run a single request to an OpenAI endpoint...)
	rm -rf ./static-input/results
	mkdir -p ./static-input/results
	./static-input/static.sh
	grep -r --include="result*" -m 1 "429" ./static-input/results | wc -l
	grep -r --include="result*" -m 1 "content" ./static-input/results | wc -l


max_seq=30
run-sequence:
	$(call log_section, Run a sequence of similar requests to an OpenAI endpoint...)
	rm -rf ./static-input/results
	mkdir -p ./static-input/results
	seq 1 $(max_seq) | time parallel -j 5 ./static-input/static.sh
	grep -r --include="result*" -m 1 "429" ./static-input/results | wc -l
	grep -r --include="result*" -m 1 "content" ./static-input/results | wc -l


run-inputs:
	$(call log_section, Run different input requests to an OpenAI endpoint...)
	rm -rf ./multi-input/results
	mkdir -p ./multi-input/results
	cat ./multi-input/inputs.txt | time parallel -j 10 ./multi-input/multiple-inputs.sh
	grep -r --include="result*" -m 1 "429" ./multi-input/results | wc -l
	grep -r --include="result*" -m 1 "content" ./multi-input/results | wc -l


OPENAI_HOST=$(shell cat variables.env | grep "API_ENDPOINT" | cut -d "=" -f 2 | xargs)
single-locust:
	$(call log_section, Run a Locust test for the same prompt 'x' times...)
	.venv/bin/locust -f ./locust-tests/single_oai_locust.py -H $(OPENAI_HOST) -u 10 --headless -r 1 -t 1m

# Testing with APIM
apim-test:
	$(call log_section, Run an APIM test...)
	rm -rf ./with-apim/results
	mkdir -p ./with-apim/results
	cat ./multi-input/inputs.txt | time parallel -j 10 ./with-apim/test-apim.sh
	grep -r --include="result*" -m 1 "429" ./with-apim/results | wc -l
	grep -r --include="result*" -m 1 "content" ./with-apim/results | wc -l


APIM_HOST=$(shell cat variables.env | grep "APIM_ENDPOINT" | cut -d "=" -f 2 | xargs)
apim-locust:
	$(call log_section, Run a Locust test against the APIM instance...)
	.venv/bin/locust -f ./locust-tests/apim_locust.py -H $(APIM_HOST) -u 100 --headless -r 1 -t 5m


# Commit local branch changes
branch=$(shell git symbolic-ref --short HEAD)
now=$(shell date '+%F_%H:%M:%S' )
git-push:
	-make cleanup
	git add . && git commit -m "Changes as of $(now)" && git push -u origin $(branch)


# Force remote to align with the local branch
force-remote:
	git push origin main --force

git-pull:
	git pull origin $(branch)
