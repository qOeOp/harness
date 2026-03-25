#!/bin/sh
set -eu

if ! command -v gh >/dev/null 2>&1; then
  echo "repo trust boundary audit: fail" >&2
  echo "- missing gh CLI" >&2
  exit 1
fi

origin_url=$(git remote get-url origin 2>/dev/null || true)
case "$origin_url" in
  git@github.com:*)
    repo_ref=${origin_url#git@github.com:}
    repo_ref=${repo_ref%.git}
    ;;
  https://github.com/*)
    repo_ref=${origin_url#https://github.com/}
    repo_ref=${repo_ref%.git}
    ;;
  *)
    echo "repo trust boundary audit: fail" >&2
    echo "- unable to derive GitHub repository from origin remote" >&2
    exit 1
    ;;
esac

owner=${repo_ref%%/*}
repo=${repo_ref#*/}
default_branch=$(gh api "repos/$owner/$repo" --jq '.default_branch')
collaborators=$(gh api "repos/$owner/$repo/collaborators" --jq 'length')
trust_mode_file=".harness/workspace/current/repo-trust-mode.md"
trust_mode="strict"

if [ -f "$trust_mode_file" ]; then
  trust_mode=$(awk '
    index($0, "- Mode: ") == 1 {
      print substr($0, length("- Mode: ") + 1)
      exit
    }
    index($0, "- Current truth:") == 1 {
      in_truth = 1
      next
    }
    in_truth && index($0, "`solo` trust mode") > 0 {
      print "solo"
      exit
    }
    in_truth && index($0, "`strict` trust mode") > 0 {
      print "strict"
      exit
    }
  ' "$trust_mode_file")
fi

failures=0

report_failure() {
  echo "- FAIL: $1" >&2
  failures=$((failures + 1))
}

report_ok() {
  echo "- OK: $1"
}

report_warn() {
  echo "- WARN: $1" >&2
}

protection_endpoint="repos/$owner/$repo/branches/$default_branch/protection"

case "$trust_mode" in
  strict)
    if [ "${collaborators:-0}" -ge 2 ]; then
      report_ok "repository has at least two collaborators with potential reviewer separation"
    else
      report_failure "repository has fewer than two collaborators; independent reviewer separation is impossible"
    fi
    ;;
  solo)
    report_ok "repo trust mode is solo"
    if [ "${collaborators:-0}" -ge 2 ]; then
      report_warn "repository has multiple collaborators; solo trust assumptions may be outdated"
    else
      report_ok "solo mode does not require an independent reviewer collaborator"
    fi
    ;;
  *)
    report_failure "unknown repo trust mode '$trust_mode'"
    ;;
esac

if ! gh api "$protection_endpoint" >/dev/null 2>&1; then
  echo "repo trust boundary audit: fail" >&2
  report_failure "default branch '$default_branch' is not protected"
  report_failure "cannot validate required checks, pull request rules, or admin enforcement"
  exit 1
fi

strict_checks=$(gh api "$protection_endpoint" --jq '.required_status_checks.strict // false')
contexts=$(gh api "$protection_endpoint" --jq '.required_status_checks.contexts[]?')
enforce_admins=$(gh api "$protection_endpoint" --jq '.enforce_admins.enabled // false')
linear_history=$(gh api "$protection_endpoint" --jq '.required_linear_history.enabled // false')
conversation_resolution=$(gh api "$protection_endpoint" --jq '.required_conversation_resolution.enabled // false')
allow_force_pushes=$(gh api "$protection_endpoint" --jq '.allow_force_pushes.enabled // false')
review_count=$(gh api "$protection_endpoint" --jq '.required_pull_request_reviews.required_approving_review_count // 0')
require_last_push_approval=$(gh api "$protection_endpoint" --jq '.required_pull_request_reviews.require_last_push_approval // false')
pull_request_rules=0
for ruleset_id in $(gh api "repos/$owner/$repo/rulesets" --jq '.[].id'); do
  has_pull_request_rule=$(gh api "repos/$owner/$repo/rulesets/$ruleset_id" --jq 'if .enforcement == "active" and any(.rules[]?; .type == "pull_request") then "yes" else "no" end')
  if [ "$has_pull_request_rule" = "yes" ]; then
    pull_request_rules=$((pull_request_rules + 1))
  fi
done

if printf '%s\n' "$contexts" | grep -qx 'governance-gates'; then
  report_ok "required status check 'governance-gates' is configured"
else
  report_failure "required status check 'governance-gates' is missing"
fi

if [ "$strict_checks" = "true" ]; then
  report_ok "required status checks are strict"
else
  report_failure "required status checks are not strict"
fi

if [ "$enforce_admins" = "true" ]; then
  report_ok "admin enforcement is enabled"
else
  report_failure "admin enforcement is disabled"
fi

if [ "$linear_history" = "true" ]; then
  report_ok "linear history is required"
else
  report_failure "linear history is not required"
fi

if [ "$conversation_resolution" = "true" ]; then
  report_ok "conversation resolution is required"
else
  report_failure "conversation resolution is not required"
fi

if [ "$allow_force_pushes" = "false" ]; then
  report_ok "force pushes are disabled"
else
  report_failure "force pushes are allowed"
fi

case "$trust_mode" in
  strict)
    if [ "$review_count" -ge 1 ]; then
      report_ok "at least one approving review is required"
    else
      report_failure "no approving review is required"
    fi

    if [ "$require_last_push_approval" = "true" ]; then
      report_ok "last push approval by another reviewer is required"
    else
      report_failure "last push approval by another reviewer is not required"
    fi
    ;;
  solo)
    if [ "$pull_request_rules" -ge 1 ]; then
      report_ok "an active pull_request ruleset enforces PR-first flow for solo mode"
    else
      report_failure "solo mode requires an active pull_request ruleset"
    fi
    if [ "$review_count" -ge 1 ] || [ "$require_last_push_approval" = "true" ]; then
      report_warn "branch protection still contains independent-review settings that are not required in solo mode"
    fi
    ;;
esac

signatures_endpoint="$protection_endpoint/required_signatures"
if gh api "$signatures_endpoint" --jq '.enabled' >/tmp/repo_trust_boundary_signatures.$$ 2>/dev/null; then
  signatures_enabled=$(cat /tmp/repo_trust_boundary_signatures.$$)
  rm -f /tmp/repo_trust_boundary_signatures.$$
  if [ "$signatures_enabled" = "true" ]; then
    report_ok "signed commits are required"
  else
    report_failure "signed commits endpoint exists but is not enabled"
  fi
else
  report_failure "signed commits are not required"
fi

head_verified=$(gh api "repos/$owner/$repo/commits/$default_branch" --jq '.commit.verification.verified')
head_reason=$(gh api "repos/$owner/$repo/commits/$default_branch" --jq '.commit.verification.reason')
if [ "$head_verified" = "true" ]; then
  report_ok "latest commit on '$default_branch' is verified"
else
  report_failure "latest commit on '$default_branch' is not verified (reason: $head_reason)"
fi

if [ "$failures" -gt 0 ]; then
  echo "repo trust boundary audit: fail" >&2
  exit 1
fi

echo "repo trust boundary audit: ok"
