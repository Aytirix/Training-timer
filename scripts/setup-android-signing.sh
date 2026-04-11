#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"

usage() {
  cat <<'EOF'
Usage:
  scripts/setup-android-signing.sh

Cette commande :
  - charge .env si présent ;
  - remplit automatiquement les variables Android release manquantes ;
  - génère des mots de passe aléatoires si besoin ;
  - crée la keystore release avec keytool ;
  - enregistre les valeurs dans .env.
EOF
}

log() {
  printf '[signing] %s\n' "$*"
}

fail() {
  printf '[signing] Error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Commande requise introuvable: $1"
}

load_env() {
  if [[ -f "$ENV_FILE" ]]; then
    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ "$line" =~ ^[[:space:]]*$ ]] && continue
      [[ "$line" =~ ^[[:space:]]*# ]] && continue

      line="${line#export }"
      key="${line%%=*}"
      value="${line#*=}"

      key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
      [[ "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue

      if [[ "$value" =~ ^\".*\"$ ]] || [[ "$value" =~ ^\'.*\'$ ]]; then
        value="${value:1:-1}"
      fi

      export "$key=$value"
    done < "$ENV_FILE"
  fi
}

random_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32
  else
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32
  fi
  printf '\n'
}

default_if_empty() {
  local current="$1"
  local fallback="$2"
  if [[ -n "$current" ]]; then
    printf '%s\n' "$current"
  else
    printf '%s\n' "$fallback"
  fi
}

upsert_env() {
  local key="$1"
  local value="$2"
  local escaped

  mkdir -p "$(dirname "$ENV_FILE")"
  touch "$ENV_FILE"

  escaped="$(printf '%s' "$value" | sed -e 's/[\/&]/\\&/g')"

  if grep -q "^${key}=" "$ENV_FILE"; then
    sed -i "s/^${key}=.*/${key}=${escaped}/" "$ENV_FILE"
  else
    printf '%s=%s\n' "$key" "$value" >> "$ENV_FILE"
  fi
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_cmd keytool
  load_env

  local keystore_path alias store_password key_password validity dname
  keystore_path="$(default_if_empty "${ANDROID_KEYSTORE_PATH:-}" "$ROOT_DIR/.secrets/android/training-timer-release.jks")"
  validity="$(default_if_empty "${ANDROID_KEYSTORE_VALIDITY_DAYS:-}" "10000")"
  dname="$(default_if_empty "${ANDROID_KEYSTORE_DNAME:-}" "CN=Training Timer, OU=Mobile, O=Training Timer, L=Paris, ST=Ile-de-France, C=FR")"

  if [[ -f "$keystore_path" ]]; then
    alias="${ANDROID_KEY_ALIAS:-}"
    store_password="${ANDROID_KEYSTORE_PASSWORD:-}"
    key_password="${ANDROID_KEY_PASSWORD:-}"
    if [[ -z "$alias" || -z "$store_password" || -z "$key_password" ]]; then
      fail "La keystore existe déjà, mais il manque ANDROID_KEY_ALIAS / ANDROID_KEYSTORE_PASSWORD / ANDROID_KEY_PASSWORD dans $ENV_FILE. Ces secrets ne peuvent pas être retrouvés automatiquement."
    fi
    log "Keystore déjà présente: $keystore_path"
  else
    alias="$(default_if_empty "${ANDROID_KEY_ALIAS:-}" "training-timer-release")"
    store_password="$(default_if_empty "${ANDROID_KEYSTORE_PASSWORD:-}" "$(random_secret)")"
    key_password="$(default_if_empty "${ANDROID_KEY_PASSWORD:-}" "$store_password")"
    mkdir -p "$(dirname "$keystore_path")"
    log "Génération de la keystore release: $keystore_path"
    keytool -genkeypair -v \
      -keystore "$keystore_path" \
      -storepass "$store_password" \
      -alias "$alias" \
      -keypass "$key_password" \
      -keyalg RSA \
      -keysize 2048 \
      -validity "$validity" \
      -dname "$dname"
  fi

  upsert_env "ANDROID_KEYSTORE_PATH" "$keystore_path"
  upsert_env "ANDROID_KEYSTORE_PASSWORD" "$store_password"
  upsert_env "ANDROID_KEY_ALIAS" "$alias"
  upsert_env "ANDROID_KEY_PASSWORD" "$key_password"
  upsert_env "ANDROID_KEYSTORE_VALIDITY_DAYS" "$validity"
  upsert_env "ANDROID_KEYSTORE_DNAME" "$dname"

  log "Configuration Android release enregistrée dans $ENV_FILE"
  log "Alias: $alias"
  log "Keystore: $keystore_path"
  log "Les mots de passe ont été sauvegardés dans $ENV_FILE"
}

main "$@"
