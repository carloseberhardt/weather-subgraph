.PHONY: help import start clean $(IMPORTS)
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST)  | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

ACCOUNT=chico
APIKEY:=$(shell stepzen whoami --apikey)
ENV=dev
ENDPOINT=${ENV}/${GRAPH}

## define the graph name
GRAPH=weather

## define the subgraphs to import for testing
IMPORTS=orders customers
orders: stepzen.config.json 
	$(import-subgraph)

customers: stepzen.config.json 
	$(import-subgraph)


define import-subgraph
	@echo "importing $@..."
	@stepzen import graphql --name=$@ --header "Authorization: apikey ${APIKEY}" "https://${ACCOUNT}.stepzen.net/${ENV}/$@/__graphql"
endef


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
	@echo "removing schemas $(IMPORTS)"
	rm -rf $(IMPORTS)
	$(foreach i, $(IMPORTS), sed -i 's/"${i}\/index.graphql"//' index.graphql;)
	rm stepzen.config.json


stepzen.config.json:
	stepzen init --endpoint ${ENDPOINT}

