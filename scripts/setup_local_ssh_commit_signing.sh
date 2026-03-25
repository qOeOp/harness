#!/bin/sh
set -eu

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$repo_root" ]; then
  echo "must run inside a git repository" >&2
  exit 1
fi

cd "$repo_root"

email="${1:-$(git config --get user.email || true)}"
pubkey_path="${2:-}"

if [ -z "$email" ]; then
  echo "missing git user.email; pass email as first argument or configure git user.email" >&2
  exit 1
fi

if [ -z "$pubkey_path" ]; then
  if [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    pubkey_path="$HOME/.ssh/id_rsa.pub"
  else
    first_key=$(ls "$HOME"/.ssh/*.pub 2>/dev/null | head -n 1 || true)
    pubkey_path="$first_key"
  fi
fi

if [ -z "$pubkey_path" ] || [ ! -f "$pubkey_path" ]; then
  echo "missing public key: $pubkey_path" >&2
  exit 1
fi

private_key_path=${pubkey_path%.pub}
if [ ! -f "$private_key_path" ]; then
  echo "missing matching private key: $private_key_path" >&2
  exit 1
fi

tmp_probe=$(mktemp /tmp/ssh-sign-probe-XXXXXX)
trap 'rm -f "$tmp_probe" "$tmp_probe.sig"' EXIT
printf 'probe\n' >"$tmp_probe"
if ! ssh-keygen -Y sign -f "$private_key_path" -n git "$tmp_probe" >/dev/null 2>&1; then
  echo "ssh-keygen does not support SSH signing" >&2
  exit 1
fi

allowed_signers_file="$repo_root/.git/info/allowed_signers"
mkdir -p "$(dirname "$allowed_signers_file")"
printf '%s ' "$email" >"$allowed_signers_file"
cat "$pubkey_path" >>"$allowed_signers_file"

git config --local gpg.format ssh
git config --local commit.gpgsign true
git config --local tag.gpgsign true
git config --local user.signingkey "$pubkey_path"
git config --local gpg.ssh.allowedSignersFile "$allowed_signers_file"

printf '%s\n' "configured repo-local SSH commit signing"
printf '%s\n' "email=$email"
printf '%s\n' "public_key=$pubkey_path"
printf '%s\n' "allowed_signers=$allowed_signers_file"
