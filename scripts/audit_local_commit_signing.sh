#!/bin/sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
  echo "local commit signing audit: fail" >&2
  echo "- missing git repository context" >&2
  exit 1
fi

cd "$repo_root"

failures=0

report_failure() {
  echo "- FAIL: $1" >&2
  failures=$((failures + 1))
}

report_ok() {
  echo "- OK: $1"
}

gpg_format=$(git config --get gpg.format || true)
commit_gpgsign=$(git config --get commit.gpgsign || true)
tag_gpgsign=$(git config --get tag.gpgsign || true)
signing_key=$(git config --get user.signingkey || true)
allowed_signers=$(git config --get gpg.ssh.allowedSignersFile || true)
user_email=$(git config --get user.email || true)

[ "$gpg_format" = "ssh" ] && report_ok "gpg.format=ssh" || report_failure "gpg.format is not ssh"
[ "$commit_gpgsign" = "true" ] && report_ok "commit.gpgsign=true" || report_failure "commit.gpgsign is not true"
[ "$tag_gpgsign" = "true" ] && report_ok "tag.gpgsign=true" || report_failure "tag.gpgsign is not true"

if [ -n "$signing_key" ] && [ -f "$signing_key" ]; then
  report_ok "user.signingkey points to an existing file"
else
  report_failure "user.signingkey is missing or points to a missing file"
fi

if [ -n "$allowed_signers" ] && [ -f "$allowed_signers" ]; then
  report_ok "allowed signers file exists"
else
  report_failure "gpg.ssh.allowedSignersFile is missing or invalid"
fi

if [ -n "$allowed_signers" ] && [ -f "$allowed_signers" ] && [ -n "$user_email" ]; then
  if grep -q "^$user_email " "$allowed_signers"; then
    report_ok "allowed signers file contains current user.email"
  else
    report_failure "allowed signers file does not contain current user.email"
  fi
fi

if [ -n "$signing_key" ] && [ -f "$signing_key" ]; then
  private_key_path=${signing_key%.pub}
  if [ -f "$private_key_path" ]; then
    tmp_probe=$(mktemp /tmp/ssh-sign-audit-XXXXXX)
    trap 'rm -f "$tmp_probe" "$tmp_probe.sig"' EXIT
    printf 'probe\n' >"$tmp_probe"
    if ssh-keygen -Y sign -f "$private_key_path" -n git "$tmp_probe" >/dev/null 2>&1; then
      report_ok "ssh-keygen can sign with the configured SSH key"
    else
      report_failure "ssh-keygen cannot sign with the configured SSH key"
    fi
  else
    report_failure "matching private key for user.signingkey is missing"
  fi
else
  report_failure "cannot test SSH signing without a valid user.signingkey"
fi

if [ -n "$signing_key" ] && [ -f "$signing_key" ] && command -v gh >/dev/null 2>&1; then
  remote_url=$(git remote get-url origin 2>/dev/null || true)
  case "$remote_url" in
    git@github.com:*|https://github.com/*)
      key_body=$(cut -d' ' -f1-2 "$signing_key")
      if gh api users/qOeOp/keys --jq '.[].key' 2>/dev/null | grep -Fqx "$key_body"; then
        report_ok "signing public key matches a published GitHub auth key for qOeOp"
      else
        echo "- WARN: signing key is not visible among published GitHub auth keys for qOeOp" >&2
      fi
      echo "- WARN: GitHub SSH signing-key registration is not audited by this script" >&2
      ;;
  esac
fi

if [ "$failures" -gt 0 ]; then
  echo "local commit signing audit: fail" >&2
  exit 1
fi

echo "local commit signing audit: ok"
