#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT_DIR}" ]]; then
    echo "${SCRIPT_NAME}: must be run inside a git repository."
    exit 1
fi

HOOKS_DIR="$(git rev-parse --git-path hooks)"
SOURCE_HOOK="${ROOT_DIR}/scripts/pre-commit.sh"
TARGET_HOOK="${HOOKS_DIR}/pre-commit"

if [[ ! -f "${SOURCE_HOOK}" ]]; then
    echo "${SCRIPT_NAME}: source hook not found at ${SOURCE_HOOK}"
    exit 1
fi

mkdir -p "${HOOKS_DIR}"
chmod +x "${SOURCE_HOOK}"

if [[ -e "${TARGET_HOOK}" && ! -L "${TARGET_HOOK}" ]]; then
    BACKUP_HOOK="${TARGET_HOOK}.bak"
    if [[ ! -e "${BACKUP_HOOK}" ]]; then
        mv "${TARGET_HOOK}" "${BACKUP_HOOK}"
        echo "${SCRIPT_NAME}: backed up existing hook to ${BACKUP_HOOK}"
    else
        rm -f "${TARGET_HOOK}"
    fi
fi

ln -sfn "${SOURCE_HOOK}" "${TARGET_HOOK}"
chmod +x "${TARGET_HOOK}"

echo "${SCRIPT_NAME}: installed pre-commit hook -> ${TARGET_HOOK}"
