SHELL = /bin/sh
BUILD_PATH = app.js
MAIN_FILE = src/NethysSearch.elm
ELM_FLAGS =

.PHONY: help
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'


.PHONY: elm
elm: ## Build elm
	elm make $(MAIN_FILE) $(ELM_FLAGS) --output=$(BUILD_PATH)


.PHONY: elm-minified
elm-minified: elm ## Build and minify elm
	npx uglifyjs $(BUILD_PATH) --compress 'pure_funcs=[F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9],pure_getters,keep_fargs=false,unsafe_comps,unsafe' | npx uglifyjs --mangle --output $(subst .js,.min.js,$(BUILD_PATH))


.PHONY: elm-live
elm-live: ## Run elm-live
	npx elm-live $(MAIN_FILE) -u -- --debug --output=$(BUILD_PATH)
