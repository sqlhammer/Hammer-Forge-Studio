#!/usr/bin/env bash
set -euo pipefail
exec python "$(dirname "$0")/milestone_status.py" "$@"
