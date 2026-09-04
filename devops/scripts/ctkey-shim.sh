#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "setenv" ]]; then
  echo "ctkey-shim only supports 'setenv'" >&2
  exit 1
fi

aws_access_key_id="${AWS_ACCESS_KEY_ID:-}"
aws_secret_access_key="${AWS_SECRET_ACCESS_KEY:-}"
aws_session_token="${AWS_SESSION_TOKEN:-}"
profile_region=""

if [[ -z "$aws_access_key_id" || -z "$aws_secret_access_key" ]]; then
  : "${AWS_PROFILE:?missing AWS_PROFILE}"
  : "${AWS_SHARED_CREDENTIALS_FILE:?missing AWS_SHARED_CREDENTIALS_FILE}"
  : "${AWS_SHARED_CREDENTIALS_FILE:?credentials file not readable}"

  mapfile -t profile_values < <(
    python3 - "$AWS_SHARED_CREDENTIALS_FILE" "$AWS_PROFILE" <<'PY'
import configparser
import sys

path, profile = sys.argv[1], sys.argv[2]
parser = configparser.RawConfigParser()

if not parser.read(path):
    raise SystemExit(f"unable to read credentials file: {path}")

if not parser.has_section(profile):
    raise SystemExit(f"profile not found in credentials file: {profile}")

section = parser[profile]
print(section.get("aws_access_key_id", ""))
print(section.get("aws_secret_access_key", ""))
print(section.get("aws_session_token", ""))
print(section.get("region", ""))
PY
  )

  aws_access_key_id="${profile_values[0]:-}"
  aws_secret_access_key="${profile_values[1]:-}"
  aws_session_token="${profile_values[2]:-}"
  profile_region="${profile_values[3]:-}"
fi

: "${aws_access_key_id:?missing aws_access_key_id}"
: "${aws_secret_access_key:?missing aws_secret_access_key}"

aws_region="${AWS_REGION:-${AWS_DEFAULT_REGION:-${profile_region:-us-east-1}}}"

printf 'export AWS_ACCESS_KEY_ID=%q\n' "$aws_access_key_id"
printf 'export AWS_SECRET_ACCESS_KEY=%q\n' "$aws_secret_access_key"

if [[ -n "$aws_session_token" ]]; then
  printf 'export AWS_SESSION_TOKEN=%q\n' "$aws_session_token"
fi

printf 'export AWS_REGION=%q\n' "$aws_region"
printf 'export AWS_DEFAULT_REGION=%q\n' "$aws_region"
