#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
API_VERSION="${GITHUB_API_VERSION:-2026-03-10}"

ARTIFACT_KIND="apk"
TAG=""
RELEASE_NAME=""
RELEASE_NOTES=""
RELEASE_NOTES_FILE=""
TARGET_COMMITISH=""
DRAFT=false
PRERELEASE=false
GENERATE_RELEASE_NOTES=true
SKIP_BUILD=false
ALLOW_DIRTY=false

RESPONSE_BODY=""
RESPONSE_CODE=""

usage() {
  cat <<'EOF'
Usage:
  scripts/release-github.sh [options]

Options:
  --tag <tag>               Tag GitHub release, default: v<version pubspec>
  --name <name>             Nom de la release, default: Training Timer <tag>
  --artifact <kind>         apk | aab | both, default: apk
  --notes <text>            Notes de release inline
  --notes-file <file>       Notes de release depuis un fichier
  --target <ref>            Branche ou SHA cible pour créer le tag
  --draft                   Crée une draft release
  --prerelease              Marque la release comme pre-release
  --no-generate-notes       Désactive les release notes GitHub auto
  --skip-build              Réutilise les artefacts déjà buildés
  --allow-dirty             Autorise un worktree Git non propre
  -h, --help                Affiche cette aide

Environment (.env):
  FLUTTER_SDK=/absolute/path/to/flutter
  ANDROID_SDK_ROOT=/absolute/path/to/android/sdk
  ANDROID_KEYSTORE_PATH=/absolute/path/to/release-keystore.jks
  ANDROID_KEYSTORE_PASSWORD=<keystore-password>
  ANDROID_KEY_ALIAS=<key-alias>
  ANDROID_KEY_PASSWORD=<key-password>
  GITHUB_TOKEN=<token with Contents: write>
  GITHUB_REPOSITORY=owner/repo   # optionnel, inféré depuis origin sinon
EOF
}

log() {
  printf '[release] %s\n' "$*"
}

fail() {
  printf '[release] Error: %s\n' "$*" >&2
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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tag)
        TAG="${2:-}"
        shift 2
        ;;
      --name)
        RELEASE_NAME="${2:-}"
        shift 2
        ;;
      --artifact)
        ARTIFACT_KIND="${2:-}"
        shift 2
        ;;
      --notes)
        RELEASE_NOTES="${2:-}"
        shift 2
        ;;
      --notes-file)
        RELEASE_NOTES_FILE="${2:-}"
        shift 2
        ;;
      --target)
        TARGET_COMMITISH="${2:-}"
        shift 2
        ;;
      --draft)
        DRAFT=true
        shift
        ;;
      --prerelease)
        PRERELEASE=true
        shift
        ;;
      --no-generate-notes)
        GENERATE_RELEASE_NOTES=false
        shift
        ;;
      --skip-build)
        SKIP_BUILD=true
        shift
        ;;
      --allow-dirty)
        ALLOW_DIRTY=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "Option inconnue: $1"
        ;;
    esac
  done
}

infer_repository() {
  if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
    printf '%s\n' "$GITHUB_REPOSITORY"
    return
  fi

  local origin_url
  origin_url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$origin_url" ]] || fail "Aucun remote origin configuré."

  if [[ "$origin_url" != *github.com* ]]; then
    fail "Le remote origin ne pointe pas vers GitHub: $origin_url"
  fi

  printf '%s\n' "$origin_url" | sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##'
}

ensure_git_state() {
  if [[ "$ALLOW_DIRTY" != true ]] && [[ -n "$(git status --porcelain)" ]]; then
    fail "Le worktree Git contient des modifications. Commit/push d'abord ou utilisez --allow-dirty."
  fi

  if [[ -z "$TARGET_COMMITISH" ]]; then
    TARGET_COMMITISH="$(git rev-parse --abbrev-ref HEAD)"
  fi

  [[ "$TARGET_COMMITISH" != "HEAD" ]] || fail "HEAD détaché. Passez --target <branche-ou-sha>."

  local remote_sha local_sha
  remote_sha="$(git ls-remote --heads origin "$TARGET_COMMITISH" | awk 'NR==1 {print $1}')"
  local_sha="$(git rev-parse HEAD)"

  if [[ -z "$remote_sha" ]]; then
    fail "La branche origin/$TARGET_COMMITISH n'existe pas. Push-la avant de publier."
  fi

  if [[ "$remote_sha" != "$local_sha" ]]; then
    fail "Le commit local n'est pas encore poussé sur origin/$TARGET_COMMITISH."
  fi
}

resolve_version() {
  local version
  version="$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*$/\1/p' pubspec.yaml | head -n 1)"
  [[ -n "$version" ]] || fail "Impossible de lire la version depuis pubspec.yaml"

  if [[ -z "$TAG" ]]; then
    TAG="v$version"
  fi

  if [[ -z "$RELEASE_NAME" ]]; then
    RELEASE_NAME="Training Timer $TAG"
  fi

  if [[ -n "$RELEASE_NOTES_FILE" ]]; then
    [[ -f "$RELEASE_NOTES_FILE" ]] || fail "Fichier de notes introuvable: $RELEASE_NOTES_FILE"
    RELEASE_NOTES="$(cat "$RELEASE_NOTES_FILE")"
    GENERATE_RELEASE_NOTES=false
  elif [[ -n "$RELEASE_NOTES" ]]; then
    GENERATE_RELEASE_NOTES=false
  fi
}

prepare_flutter() {
  [[ -n "${FLUTTER_SDK:-}" ]] || fail "FLUTTER_SDK doit être défini dans .env"
  [[ -x "$FLUTTER_SDK/bin/flutter" ]] || fail "Flutter introuvable à: $FLUTTER_SDK/bin/flutter"
  export PATH="$FLUTTER_SDK/bin:$PATH"

  if [[ -n "${ANDROID_SDK_ROOT:-}" ]]; then
    export ANDROID_SDK_ROOT
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
  fi
}

ensure_release_signing() {
  [[ -n "${ANDROID_KEYSTORE_PATH:-}" ]] || fail "ANDROID_KEYSTORE_PATH doit être défini dans .env"
  [[ -f "$ANDROID_KEYSTORE_PATH" ]] || fail "Keystore release introuvable: $ANDROID_KEYSTORE_PATH"
  [[ -n "${ANDROID_KEYSTORE_PASSWORD:-}" ]] || fail "ANDROID_KEYSTORE_PASSWORD doit être défini dans .env"
  [[ -n "${ANDROID_KEY_ALIAS:-}" ]] || fail "ANDROID_KEY_ALIAS doit être défini dans .env"
  [[ -n "${ANDROID_KEY_PASSWORD:-}" ]] || fail "ANDROID_KEY_PASSWORD doit être défini dans .env"
}

github_request_json() {
  local method="$1"
  local url="$2"
  local data="${3:-}"
  local tmp
  tmp="$(mktemp)"

  if [[ -n "$data" ]]; then
    RESPONSE_CODE="$(
      curl -sS -L -o "$tmp" -w '%{http_code}' \
        -X "$method" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: $API_VERSION" \
        "$url" \
        -d "$data"
    )"
  else
    RESPONSE_CODE="$(
      curl -sS -L -o "$tmp" -w '%{http_code}' \
        -X "$method" \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: $API_VERSION" \
        "$url"
    )"
  fi

  RESPONSE_BODY="$(cat "$tmp")"
  rm -f "$tmp"
}

github_delete() {
  local url="$1"
  local code
  code="$(
    curl -sS -L -o /dev/null -w '%{http_code}' \
      -X DELETE \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: $API_VERSION" \
      "$url"
  )"
  [[ "$code" == "204" ]] || fail "Suppression GitHub échouée sur $url (HTTP $code)"
}

github_upload_asset() {
  local upload_url="$1"
  local asset_path="$2"
  local content_type="$3"
  local filename
  local code

  filename="$(basename "$asset_path")"
  code="$(
    curl -sS -L -o /dev/null -w '%{http_code}' \
      -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "Authorization: Bearer $GITHUB_TOKEN" \
      -H "X-GitHub-Api-Version: $API_VERSION" \
      -H "Content-Type: $content_type" \
      "${upload_url}?name=${filename}" \
      --data-binary "@${asset_path}"
  )"

  [[ "$code" == "201" ]] || fail "Upload de l'asset $filename échoué (HTTP $code)"
}

asset_content_type() {
  case "$1" in
    *.apk)
      printf 'application/vnd.android.package-archive\n'
      ;;
    *.aab)
      printf 'application/octet-stream\n'
      ;;
    *.sha256)
      printf 'text/plain\n'
      ;;
    *)
      printf 'application/octet-stream\n'
      ;;
  esac
}

build_artifacts() {
  local safe_tag output_dir
  safe_tag="$(printf '%s' "$TAG" | sed 's/[^A-Za-z0-9._+-]/_/g')"
  output_dir="$ROOT_DIR/build/releases/$safe_tag"
  mkdir -p "$output_dir"

  log "flutter pub get"
  flutter pub get

  if [[ "$SKIP_BUILD" != true ]]; then
    case "$ARTIFACT_KIND" in
      apk)
        log "flutter build apk --release"
        flutter build apk --release
        ;;
      aab)
        log "flutter build appbundle --release"
        flutter build appbundle --release
        ;;
      both)
        log "flutter build apk --release"
        flutter build apk --release
        log "flutter build appbundle --release"
        flutter build appbundle --release
        ;;
      *)
        fail "Valeur --artifact invalide: $ARTIFACT_KIND"
        ;;
    esac
  fi

  RELEASE_ASSETS=()

  if [[ "$ARTIFACT_KIND" == "apk" || "$ARTIFACT_KIND" == "both" ]]; then
    local apk_src apk_dst
    apk_src="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
    [[ -f "$apk_src" ]] || fail "APK release introuvable: $apk_src"
    apk_dst="$output_dir/training-timer-${safe_tag}-android-release.apk"
    cp "$apk_src" "$apk_dst"
    RELEASE_ASSETS+=("$apk_dst")
  fi

  if [[ "$ARTIFACT_KIND" == "aab" || "$ARTIFACT_KIND" == "both" ]]; then
    local aab_src aab_dst
    aab_src="$ROOT_DIR/build/app/outputs/bundle/release/app-release.aab"
    [[ -f "$aab_src" ]] || fail "AAB release introuvable: $aab_src"
    aab_dst="$output_dir/training-timer-${safe_tag}-android-release.aab"
    cp "$aab_src" "$aab_dst"
    RELEASE_ASSETS+=("$aab_dst")
  fi

  local asset sha_file
  for asset in "${RELEASE_ASSETS[@]}"; do
    sha_file="${asset}.sha256"
    (
      cd "$(dirname "$asset")"
      sha256sum "$(basename "$asset")" > "$(basename "$sha_file")"
    )
    RELEASE_ASSETS+=("$sha_file")
  done

  log "Artefacts prêts dans $output_dir"
}

get_or_create_release() {
  local repository="$1"
  local release_url

  github_request_json GET "https://api.github.com/repos/${repository}/releases/tags/${TAG}"
  case "$RESPONSE_CODE" in
    200)
      RELEASE_JSON="$RESPONSE_BODY"
      log "Release existante trouvée pour $TAG"
      ;;
    404)
      local payload
      payload="$(
        jq -n \
          --arg tag "$TAG" \
          --arg target "$TARGET_COMMITISH" \
          --arg name "$RELEASE_NAME" \
          --arg body "$RELEASE_NOTES" \
          --argjson draft "$DRAFT" \
          --argjson prerelease "$PRERELEASE" \
          --argjson generate_notes "$GENERATE_RELEASE_NOTES" \
          '{
            tag_name: $tag,
            target_commitish: $target,
            name: $name,
            draft: $draft,
            prerelease: $prerelease,
            generate_release_notes: $generate_notes
          } + (if $body != "" then {body: $body} else {} end)'
      )"

      github_request_json POST "https://api.github.com/repos/${repository}/releases" "$payload"
      [[ "$RESPONSE_CODE" == "201" ]] || fail "Création de release échouée (HTTP $RESPONSE_CODE): $RESPONSE_BODY"
      RELEASE_JSON="$RESPONSE_BODY"
      log "Release créée pour $TAG"
      ;;
    *)
      fail "Impossible de récupérer la release pour $TAG (HTTP $RESPONSE_CODE): $RESPONSE_BODY"
      ;;
  esac

  release_url="$(jq -r '.html_url' <<< "$RELEASE_JSON")"
  RELEASE_ID="$(jq -r '.id' <<< "$RELEASE_JSON")"
  RELEASE_UPLOAD_URL="$(jq -r '.upload_url' <<< "$RELEASE_JSON" | sed 's/{?name,label}//')"
  RELEASE_HTML_URL="$release_url"
}

delete_existing_assets() {
  local asset_name asset_id
  for asset_name in "$@"; do
    asset_id="$(
      jq -r --arg name "$asset_name" '.assets[]? | select(.name == $name) | .id' <<< "$RELEASE_JSON" | head -n 1
    )"
    if [[ -n "$asset_id" ]]; then
      log "Suppression de l'ancien asset $asset_name"
      github_delete "https://api.github.com/repos/${REPOSITORY}/releases/assets/${asset_id}"
    fi
  done
}

upload_assets() {
  local asset asset_name content_type

  for asset in "${RELEASE_ASSETS[@]}"; do
    asset_name="$(basename "$asset")"
    delete_existing_assets "$asset_name"
    content_type="$(asset_content_type "$asset")"
    log "Upload de $asset_name"
    github_upload_asset "$RELEASE_UPLOAD_URL" "$asset" "$content_type"
  done
}

main() {
  parse_args "$@"
  load_env

  require_cmd git
  require_cmd curl
  require_cmd jq
  require_cmd sha256sum

  [[ -n "${GITHUB_TOKEN:-}" ]] || fail "GITHUB_TOKEN doit être défini dans .env"

  prepare_flutter
  ensure_release_signing
  ensure_git_state
  resolve_version

  REPOSITORY="$(infer_repository)"
  log "Repository GitHub: $REPOSITORY"
  log "Target commitish: $TARGET_COMMITISH"
  log "Tag de release: $TAG"
  build_artifacts
  get_or_create_release "$REPOSITORY"
  upload_assets

  printf '\n'
  log "Release publiée: $RELEASE_HTML_URL"
  log "Artefacts uploadés:"
  printf '%s\n' "${RELEASE_ASSETS[@]}"
}

main "$@"
