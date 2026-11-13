#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "${ROOT_DIR}" ]]; then
    echo "${SCRIPT_NAME}: must be run inside a git repository."
    exit 1
fi

cd "${ROOT_DIR}"

# Collect staged Swift files.
swift_files=()
while IFS= read -r -d '' file; do
    if [[ "${file}" == *.swift ]]; then
        swift_files+=("${file}")
    fi
done < <(git diff --cached --name-only --diff-filter=ACMR -z)

if [[ ${#swift_files[@]} -eq 0 ]]; then
    echo "${SCRIPT_NAME}: no staged Swift files, skipping format check."
    exit 0
fi

# Check formatting without modifying files.
echo "${SCRIPT_NAME}: checking Swift formatting (${#swift_files[@]} source files)..."

set +e
format_output="$(xcrun swift format lint --strict "${swift_files[@]}" 2>&1)"
format_status=$?
set -e

if [[ ${format_status} -ne 0 ]]; then
    echo ""
    echo "${SCRIPT_NAME}: commit blocked due to Swift formatting violations."
    echo "${SCRIPT_NAME}: run the following to fix formatting:"
    echo "  xcrun swift format format --in-place ${swift_files[*]}"
    echo ""
    echo "${format_output}"
    exit 1
fi

echo "${SCRIPT_NAME}: formatting checks passed."
exit 0
