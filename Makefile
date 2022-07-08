## Front matter -- these should change for a new project
## the graph name for this project
GRAPH=weather
## stepzen API key for logged in account
APIKEY:=$(shell stepzen whoami --apikey)
## default environment to use in {env}/{graph} endpoint pattern
ENV=dev
## endpoint to deploy to
ENDPOINT=${ENV}/${GRAPH}
## stepzen account name to use when importing subgraphs
ACCOUNT=chico

## define the subgraphs to import for testing, empty for none
IMPORTS=orders customers
${IMPORTS}: stepzen.config.json
	$(import-subgraph)

define import-subgraph
	@echo "importing $@..."
	@stepzen import graphql --name=$@ --header "Authorization: apikey ${APIKEY}" "https://${ACCOUNT}.stepzen.net/${ENV}/$@/__graphql"
endef

## Standard rules -- these should not change
.PHONY: help import start clean $(IMPORTS)
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST)  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'


describe: ## List the current configuration
	@echo "Account: \t${ACCOUNT}"
	@echo "Endpoint: \t${ENDPOINT}"
	@echo "Subgraphs: \t${IMPORTS}"

import: $(IMPORTS) ## import all external schemas -> "make import [ENV={environment}]"


start: stepzen.config.json ## deploy schema and run local proxy for testing
	@echo "uploading and deploying with stepzen start"
	stepzen start


deploy: stepzen.config.json ## upload and deploy schema and configuration
ifneq ("$(wildcard config.yaml)","")
	@echo "uploading configurationset..."
	stepzen upload configurationset ${ENDPOINT} --file=config.yaml
endif
	@echo "uploading schema..."
	stepzen upload schema ${ENDPOINT} --dir=.
	@echo "deploying schema to ${ENDPOINT}..."
	stepzen deploy --schema=${ENDPOINT} ${ENDPOINT}


clean: ## remove all external schemas specified in IMPORTS
	@echo "removing external schemas ${IMPORTS}..."
	$(foreach i, $(IMPORTS), rm -rf $i;sed -i 's/"${i}\/index.graphql"//' index.graphql;)
	rm -f stepzen.config.json


stepzen.config.json:
	stepzen init --endpoint ${ENDPOINT}

