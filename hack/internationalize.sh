#!/bin/bash
#
# internationalize.sh - Restructure docs directory for mkdocs-static-i18n plugin
#
# Usage:
#   hack/internationalize.sh <base-path> [--netlify]
#
# The mkdocs-static-i18n plugin expects a directory structure with language
# subdirectories under docs/ (e.g., docs/en/, docs/es/, docs/zh/). This script
# moves the existing docs content into docs/en/ and copies translation files
# from i18n/ into docs/.
#
# The --netlify flag applies additional transforms needed for the Netlify build
# environment (site_url and docs_dir adjustments in mkdocs.yml).

set -euo pipefail

BASE="${1:?Usage: $0 <base-path> [--netlify]}"
NETLIFY=false

if [[ "${2:-}" == "--netlify" ]]; then
    NETLIFY=true
fi

# Remove any pre-existing language dirs that may conflict
rm -rf "${BASE}/docs/es" "${BASE}/docs/zh"

# Create the English content directory
mkdir -p "${BASE}/docs/en"

# Move all docs content into en/, preserving shared assets at the top level
find "${BASE}/docs/" -mindepth 1 -maxdepth 1 \
    ! -name 'assets' \
    ! -name '_redirects' \
    ! -name 'stylesheets' \
    ! -name 'en' \
    ! -name '.nav.yml' \
    -print0 | xargs -0 -r mv -t "${BASE}/docs/en/"

# Copy index as welcome page (used as landing page for English)
cp "${BASE}/docs/en/index.md" "${BASE}/docs/en/welcome.md"

# Copy navigation config into the English directory
cp -r "${BASE}/docs/.nav.yml" "${BASE}/docs/en/"

# Copy translation directories into docs/
cp -r "${BASE}/i18n/"* "${BASE}/docs/."

# Netlify-specific transforms
if [[ "${NETLIFY}" == "true" ]]; then
    sed -i 's|site_url: https://kubevirt.io/docs|site_url: https://kubevirt.io/|' "${BASE}/mkdocs.yml"
    sed -i 's/docs_dir: docs/docs_dir:/' "${BASE}/mkdocs.yml"
fi
