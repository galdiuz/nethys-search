SHELL = /bin/sh
BUILD_PATH = app.js
MAIN_FILE = src/Main.elm

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


.PHONY: elm
elm: ## Build elm
	elm make $(MAIN_FILE) --output=$(BUILD_PATH)


.PHONY: elm-live
elm-live: ## Run elm-live
	npx elm-live $(MAIN_FILE) -u -- --debug --output=$(BUILD_PATH)
