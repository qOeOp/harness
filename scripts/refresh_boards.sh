#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$script_dir/lib_state.sh"

mode="${1:-}"
check_only=0
actor="${STATE_ACTOR:-}"
changed_targets="none"

case "$mode" in
  ""|--write) ;;
  --check) check_only=1 ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 1
    ;;
esac

if [ "$check_only" -ne 1 ]; then
  require_explicit_state_actor "$actor" "$0"
fi

export STATE_INVOKER="${STATE_INVOKER:-$(default_state_invoker "$0")}"
ensure_state_dirs

company_tmp=$(mktemp)
founder_tmp=$(mktemp)
ok=1

append_changed_target() {
  target="$1"

  if value_is_missing "$changed_targets"; then
    changed_targets="$target"
  else
    changed_targets="${changed_targets},$target"
  fi
}

commit_or_check() {
  tmp="$1"
  target="$2"

  if [ "$check_only" -eq 1 ]; then
    if [ ! -f "$target" ] || ! cmp -s "$tmp" "$target"; then
      echo "stale board: $target" >&2
      ok=0
    fi
    rm -f "$tmp"
  else
    target_changed=1
    if [ -f "$target" ] && cmp -s "$tmp" "$target"; then
      target_changed=0
    fi
    mv "$tmp" "$target"
    if [ "$target_changed" -eq 1 ]; then
      append_changed_target "$target"
    fi
  fi
}

cat >"$company_tmp" <<EOF
# Company Board

- Generated at: $(date +%F)
- Generated only: true
- Source of truth: .harness/workspace/state/items/
- Refresh command: ./.agents/skills/harness/scripts/refresh_boards.sh

| Work Item | Type | Status | Interrupt Marker | Priority | Owner | Required Departments | Current Blocker | Founder Escalation | Last Updated |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
EOF

cat >"$founder_tmp" <<EOF
# Founder Board

- Generated at: $(date +%F)
- Generated only: true
- Scope: pending founder decisions and acceptance items only
- Refresh command: ./.agents/skills/harness/scripts/refresh_boards.sh

| Work Item | Status | Interrupt Marker | Why It Matters | Decision Needed | Deadline | Supporting Pack |
| --- | --- | --- | --- | --- | --- | --- |
EOF

company_rows=0
founder_rows=0

for file in $(list_work_items); do
  id=$(field_value "$file" "ID")
  title=$(field_value "$file" "Title")
  type=$(field_value "$file" "Type")
  status=$(field_value "$file" "Status")
  priority=$(field_value "$file" "Priority")
  owner=$(field_value "$file" "Owner")
  required_departments=$(pretty_csv "$(field_value "$file" "Required departments")")
  current_blocker=$(sanitize_board_cell "$(field_value "$file" "Current blocker")")
  founder_escalation=$(field_value "$file" "Founder escalation")
  interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")
  updated_at=$(field_value "$file" "Updated at")
  why_it_matters=$(sanitize_board_cell "$(field_value "$file" "Why it matters")")
  decision_needed=$(sanitize_board_cell "$(field_value "$file" "Decision needed")")
  deadline=$(sanitize_board_cell "$(field_value "$file" "Deadline")")
  supporting_pack=$(sanitize_board_cell "$(first_linked_artifact_path "$file")")

  printf '| %s: %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' \
    "$(sanitize_board_cell "$id")" \
    "$(sanitize_board_cell "$title")" \
    "$(sanitize_board_cell "$type")" \
    "$(sanitize_board_cell "$status")" \
    "$(sanitize_board_cell "$interrupt_marker")" \
    "$(sanitize_board_cell "$priority")" \
    "$(sanitize_board_cell "$owner")" \
    "$(sanitize_board_cell "$required_departments")" \
    "$current_blocker" \
    "$(sanitize_board_cell "$founder_escalation")" \
    "$(sanitize_board_cell "$updated_at")" >>"$company_tmp"
  company_rows=$((company_rows + 1))

  if [ "$founder_escalation" = "pending-founder" ] || [ "$interrupt_marker" = "founder-review-required" ]; then
    printf '| %s: %s | %s | %s | %s | %s | %s | %s |\n' \
      "$(sanitize_board_cell "$id")" \
      "$(sanitize_board_cell "$title")" \
      "$(sanitize_board_cell "$status")" \
      "$(sanitize_board_cell "$interrupt_marker")" \
      "$why_it_matters" \
      "$decision_needed" \
      "$deadline" \
      "$supporting_pack" >>"$founder_tmp"
    founder_rows=$((founder_rows + 1))
  fi
done

if [ "$company_rows" -eq 0 ]; then
  echo '| none | - | - | - | - | - | - | - | - | - |' >>"$company_tmp"
fi

if [ "$founder_rows" -eq 0 ]; then
  echo '| none | - | - | - | - | - | - |' >>"$founder_tmp"
fi

commit_or_check "$company_tmp" "$state_boards_dir/company.md"
commit_or_check "$founder_tmp" "$state_boards_dir/founder.md"

for department in $(list_departments); do
  dept_title=$(slug_to_title "$department")
  dept_dir=".harness/workspace/departments/$department/workspace"
  dept_tmp=$(mktemp)

  cat >"$dept_tmp" <<EOF
# Department Board: $dept_title

- Generated at: $(date +%F)
- Generated only: true
- Scope: work items with explicit participation for $department
- Refresh command: ./.agents/skills/harness/scripts/refresh_boards.sh

| Work Item | Participation | Local Status | Interrupt Marker | Upstream Dependency | Next Handoff | Artifact Due |
| --- | --- | --- | --- | --- | --- | --- |
EOF

  dept_rows=0
  for file in $(list_work_items); do
    if participation=$(department_participation "$file" "$department" 2>/dev/null); then
      id=$(field_value "$file" "ID")
      title=$(field_value "$file" "Title")
      status=$(field_value "$file" "Status")
      interrupt_marker=$(field_value_or_none "$file" "Interrupt marker")
      blocked_by=$(sanitize_board_cell "$(field_value "$file" "Blocked by")")
      next_handoff=$(sanitize_board_cell "$(field_value "$file" "Next handoff")")
      due_review_at=$(sanitize_board_cell "$(field_value "$file" "Due review at")")

      printf '| %s: %s | %s | %s | %s | %s | %s | %s |\n' \
        "$(sanitize_board_cell "$id")" \
        "$(sanitize_board_cell "$title")" \
        "$(sanitize_board_cell "$participation")" \
        "$(sanitize_board_cell "$status")" \
        "$(sanitize_board_cell "$interrupt_marker")" \
        "$blocked_by" \
        "$next_handoff" \
        "$due_review_at" >>"$dept_tmp"
      dept_rows=$((dept_rows + 1))
    fi
  done

  if [ "$dept_rows" -eq 0 ]; then
    echo '| none | - | - | - | - | - | - |' >>"$dept_tmp"
  fi

  commit_or_check "$dept_tmp" "$dept_dir/board.md"
done

if [ "$check_only" -eq 1 ]; then
  if [ "$ok" -eq 1 ]; then
    echo "boards in sync"
    exit 0
  fi
  exit 1
fi

if ! value_is_missing "$changed_targets"; then
  write_board_refresh_event "$changed_targets" "$actor" >/dev/null
fi

echo "$state_boards_dir/company.md"
echo "$state_boards_dir/founder.md"
