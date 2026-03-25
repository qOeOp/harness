#!/bin/sh
set -eu

git config core.hooksPath .githooks
printf '%s\n' "git hooks enabled at .githooks"
