.DEFAULT_GOAL := help
SHELL := /usr/bin/env bash

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
ENV_FILE ?= .env

-include $(ENV_FILE)

FLUTTER_SDK ?= $(HOME)/Documents/github/essence/.tooling/flutter
FLUTTER := $(FLUTTER_SDK)/bin/flutter
FLUTTER_ENV := PATH=$(FLUTTER_SDK)/bin:$$PATH
ANDROID_SDK_ROOT ?= $(HOME)/Android/Sdk
ADB := $(ANDROID_SDK_ROOT)/platform-tools/adb

.PHONY: help
help: ## general: Afficher les commandes disponibles
	@awk '\
		function underline(value,    i, line) { \
			line = ""; \
			for (i = 0; i < length(value); i++) line = line "-"; \
			return line; \
		} \
		BEGIN { \
			FS = ":.*## "; \
			order[1] = "general"; \
			order[2] = "app"; \
			order[3] = "quality"; \
			title["general"] = "General"; \
			title["app"] = "App"; \
			title["quality"] = "Quality"; \
			printf "\n"; \
			printf "Training Timer developer commands\n"; \
			printf "=================================\n\n"; \
			printf "Quick Start\n"; \
			printf "-----------\n"; \
			printf "  %-24s %s\n", "make app-get", "Recuperer les dependances Flutter"; \
			printf "  %-24s %s\n", "make app-run-linux", "Lancer la preview desktop Linux"; \
			printf "  %-24s %s\n", "make app-adb-devices", "Lister les appareils Android vus par ADB"; \
			printf "  %-24s %s\n", "make app-run-adb", "Choisir un appareil ADB puis lancer l app"; \
			printf "  %-24s %s\n", "make check", "Analyser et tester l app"; \
			printf "\n"; \
		} \
		/^[a-zA-Z0-9_.-]+:.*## / { \
			split($$2, meta, ": "); \
			category = meta[1]; \
			description = substr($$2, length(category) + 3); \
			rows[category] = rows[category] sprintf("  %-24s %s\n", $$1, description); \
		} \
		END { \
			for (i = 1; i <= 3; i++) { \
				category = order[i]; \
				if (rows[category] == "") continue; \
				printf "%s\n", title[category]; \
				printf "%s\n", underline(title[category]); \
				printf "%s\n", rows[category]; \
			} \
			printf "\n"; \
		}' $(MAKEFILE_LIST)

.PHONY: app-get
app-get: ## app: Recuperer les dependances Flutter
	$(FLUTTER_ENV) $(FLUTTER) pub get

.PHONY: app-analyze
app-analyze: ## app: Lancer l analyse statique Flutter
	$(FLUTTER_ENV) $(FLUTTER) analyze

.PHONY: app-test
app-test: ## app: Lancer les tests Flutter
	$(FLUTTER_ENV) $(FLUTTER) test

.PHONY: app-run-linux
app-run-linux: ## app: Lancer la preview desktop Linux
	$(FLUTTER_ENV) $(FLUTTER) run -d linux

.PHONY: app-run-local
app-run-local: app-run-linux ## app: Alias de compatibilite vers la preview Linux

.PHONY: app-devices
app-devices: ## app: Lister les devices Flutter detectes
	$(FLUTTER_ENV) $(FLUTTER) devices

.PHONY: app-adb-devices
app-adb-devices: ## app: Lister les appareils Android visibles par ADB
	@$(ADB) start-server >/dev/null
	@devices="$$( $(ADB) devices -l | awk 'NR > 1 && NF { \
		id = $$1; \
		status = $$2; \
		sub($$1 "[[:space:]]+" $$2 "[[:space:]]*", "", $$0); \
		details = $$0; \
		gsub(/^[[:space:]]+/, "", details); \
		printf "  %-24s %-12s %s\n", id, status, details; \
	}' )"; \
	if [ -z "$$devices" ]; then \
		echo "Aucun appareil ADB detecte."; \
	else \
		echo "Appareils ADB detectes:"; \
		printf "%s\n" "$$devices"; \
	fi

.PHONY: app-install-adb
app-install-adb: ## app: Choisir un appareil ADB pret puis installer l app dessus
	@$(ADB) start-server >/dev/null
	@mapfile -t devices < <($(ADB) devices -l | awk 'NR > 1 && $$2 == "device" { \
		id = $$1; \
		sub($$1 "[[:space:]]+" $$2 "[[:space:]]*", "", $$0); \
		details = $$0; \
		gsub(/^[[:space:]]+/, "", details); \
		print id "\t" details; \
	}'); \
	if [ "$${#devices[@]}" -eq 0 ]; then \
		echo "Aucun appareil ADB pret. Active le debogage USB et accepte la cle RSA sur le telephone."; \
		exit 1; \
	fi; \
	echo "Appareils ADB prets:"; \
	for index in "$${!devices[@]}"; do \
		device_id="$${devices[$$index]%%$$'\t'*}"; \
		device_label="$${devices[$$index]#*$$'\t'}"; \
		printf "  [%d] %s %s\n" "$$((index + 1))" "$$device_id" "$$device_label"; \
	done; \
	printf "Choisis un appareil [1-%d] : " "$${#devices[@]}"; \
	read -r choice; \
	if ! [[ "$$choice" =~ ^[0-9]+$$ ]] || [ "$$choice" -lt 1 ] || [ "$$choice" -gt "$${#devices[@]}" ]; then \
		echo "Choix invalide."; \
		exit 1; \
	fi; \
	selected="$${devices[$$((choice - 1))]}"; \
	device_id="$${selected%%$$'\t'*}"; \
	echo "Preparation de $$device_id..."; \
	$(FLUTTER_ENV) $(FLUTTER) build apk --debug; \
	$(FLUTTER_ENV) $(FLUTTER) install -d "$$device_id" --debug --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk

.PHONY: app-run-adb
app-run-adb: ## app: Choisir un appareil ADB pret puis lancer l app dessus
	@$(ADB) start-server >/dev/null
	@mapfile -t devices < <($(ADB) devices -l | awk 'NR > 1 && $$2 == "device" { \
		id = $$1; \
		sub($$1 "[[:space:]]+" $$2 "[[:space:]]*", "", $$0); \
		details = $$0; \
		gsub(/^[[:space:]]+/, "", details); \
		print id "\t" details; \
	}'); \
	if [ "$${#devices[@]}" -eq 0 ]; then \
		echo "Aucun appareil ADB pret. Active le debogage USB et accepte la cle RSA sur le telephone."; \
		exit 1; \
	fi; \
	echo "Appareils ADB prets:"; \
	for index in "$${!devices[@]}"; do \
		device_id="$${devices[$$index]%%$$'\t'*}"; \
		device_label="$${devices[$$index]#*$$'\t'}"; \
		printf "  [%d] %s %s\n" "$$((index + 1))" "$$device_id" "$$device_label"; \
	done; \
	printf "Choisis un appareil [1-%d] : " "$${#devices[@]}"; \
	read -r choice; \
	if ! [[ "$$choice" =~ ^[0-9]+$$ ]] || [ "$$choice" -lt 1 ] || [ "$$choice" -gt "$${#devices[@]}" ]; then \
		echo "Choix invalide."; \
		exit 1; \
	fi; \
	selected="$${devices[$$((choice - 1))]}"; \
	device_id="$${selected%%$$'\t'*}"; \
	echo "Lancement sur $$device_id..."; \
	$(FLUTTER_ENV) $(FLUTTER) run -d "$$device_id"

.PHONY: app-release-github
app-release-github: ## app: Builder l app en release puis publier les artefacts sur GitHub
	@$(ROOT_DIR)/scripts/release-github.sh $(ARGS)

.PHONY: check
check: ## quality: Analyser et tester l app Flutter
	$(MAKE) app-analyze
	$(MAKE) app-test
