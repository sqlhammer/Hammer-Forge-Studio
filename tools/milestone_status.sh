#!/usr/bin/env bash
# milestone_status.sh — Parse ticket frontmatter and output a compact milestone status table.
# Usage: bash tools/milestone_status.sh [M#]
# If no milestone is given, defaults to the active (non-Complete) milestone from milestones.md.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TICKETS_DIR="$REPO_ROOT/tickets"
MILESTONES_FILE="$REPO_ROOT/docs/studio/milestones.md"

# --- Determine target milestone ---
if [[ $# -ge 1 ]]; then
    # Normalize: accept "5", "M5", "m5"
    RAW="$1"
    RAW="${RAW#[Mm]}"          # strip leading M/m if present
    TARGET="M${RAW}"
else
    # Auto-detect: find the first non-Complete milestone from milestones.md
    TARGET=""
    while IFS='|' read -r _ ms_id _ _ status _; do
        ms_id="$(echo "$ms_id" | tr -d '\r' | xargs)"
        status="$(echo "$status" | tr -d '\r' | xargs)"
        if [[ "$status" != "Complete" && "$ms_id" =~ ^M[0-9]+$ ]]; then
            TARGET="$ms_id"
            break
        fi
    done < <(grep '^| M[0-9]' "$MILESTONES_FILE")

    if [[ -z "$TARGET" ]]; then
        echo "ERROR: Could not auto-detect active milestone from milestones.md" >&2
        exit 1
    fi
fi

# --- Parse ticket files ---
# Arrays to collect ticket data
declare -a ROWS=()
DONE=0; IN_PROGRESS=0; OPEN=0; TOTAL=0
declare -A STATUS_MAP=()  # ticket_id -> status (for dependency checking)

for ticket_file in "$TICKETS_DIR"/TICKET-*.md "$TICKETS_DIR"/*/TICKET-*.md; do
    [[ -f "$ticket_file" ]] || continue

    # Extract frontmatter (between first --- and second ---)
    in_front=false
    id="" title="" status="" owner="" depends="" milestone="" phase=""

    while IFS= read -r line; do
        line="${line//$'\r'/}"  # strip CRLF
        if [[ "$line" == "---" ]]; then
            if $in_front; then break; fi
            in_front=true
            continue
        fi
        $in_front || continue

        key="${line%%:*}"
        val="${line#*: }"

        case "$key" in
            id)         id="$val" ;;
            title)      title="${val//\"/}" ;;
            status)     status="$val" ;;
            owner)      owner="$val" ;;
            depends_on) depends="$val" ;;
            milestone)  milestone="${val//\"/}" ;;
            phase)      phase="${val//\"/}" ;;
        esac
    done < "$ticket_file"

    # Store status for dependency checking (all tickets, not just target milestone)
    if [[ -n "$id" ]]; then
        STATUS_MAP["$id"]="$status"
    fi

    # Filter to target milestone
    [[ "$milestone" == "$TARGET" ]] || continue

    # Clean up depends_on: "[TICKET-0001, TICKET-0002]" -> "TICKET-0001, TICKET-0002"
    depends="${depends#\[}"
    depends="${depends%\]}"
    depends="$(echo "$depends" | xargs)"
    [[ "$depends" == "[]" ]] && depends=""

    ROWS+=("$id|$title|$status|$owner|$phase|$depends")
    TOTAL=$((TOTAL + 1))

    case "$status" in
        DONE)        DONE=$((DONE + 1)) ;;
        IN_PROGRESS) IN_PROGRESS=$((IN_PROGRESS + 1)) ;;
        *)           OPEN=$((OPEN + 1)) ;;
    esac
done

if [[ $TOTAL -eq 0 ]]; then
    echo "No tickets found for milestone $TARGET"
    exit 0
fi

# --- Sort rows by ticket ID ---
IFS=$'\n' SORTED=($(printf '%s\n' "${ROWS[@]}" | sort)); unset IFS

# --- Output table ---
echo "## $TARGET Milestone Status"
echo ""
echo "| Ticket | Title | Status | Owner | Phase | Dependencies |"
echo "|--------|-------|--------|-------|-------|--------------|"

for row in "${SORTED[@]}"; do
    IFS='|' read -r t_id t_title t_status t_owner t_phase t_deps <<< "$row"
    # Truncate long titles for compactness
    if [[ ${#t_title} -gt 50 ]]; then
        t_title="${t_title:0:47}..."
    fi
    echo "| $t_id | $t_title | $t_status | $t_owner | $t_phase | ${t_deps:--} |"
done

echo ""
echo "**Stats:** $DONE/$TOTAL DONE, $IN_PROGRESS IN_PROGRESS, $OPEN OPEN"

# --- Check for dependency violations ---
VIOLATIONS=()
for row in "${SORTED[@]}"; do
    IFS='|' read -r t_id _ t_status _ _ t_deps <<< "$row"
    # Only check tickets that have been started
    [[ "$t_status" == "IN_PROGRESS" || "$t_status" == "DONE" ]] || continue
    [[ -n "$t_deps" && "$t_deps" != "-" ]] || continue

    # Parse comma-separated dependency list
    IFS=',' read -ra DEP_LIST <<< "$t_deps"
    for dep in "${DEP_LIST[@]}"; do
        dep="$(echo "$dep" | xargs)"
        [[ -n "$dep" ]] || continue
        dep_status="${STATUS_MAP[$dep]:-UNKNOWN}"
        if [[ "$dep_status" != "DONE" ]]; then
            VIOLATIONS+=("$t_id depends on $dep ($dep_status)")
        fi
    done
done

if [[ ${#VIOLATIONS[@]} -gt 0 ]]; then
    echo ""
    echo "**Dependency Violations:**"
    for v in "${VIOLATIONS[@]}"; do
        echo "- $v"
    done
fi
