#!/bin/sh
set -eu

dev_workspace="${DEV_WORKSPACE:-}"

if [ -n "$dev_workspace" ]; then
  dev_workspace_host="4i-${dev_workspace}.dev.4innovation.cms.gov"
  dev_workspace_api_host="4i-${dev_workspace}-api.dev.4innovation.cms.gov"
else
  dev_workspace_host="invalid-dev-workspace.local"
  dev_workspace_api_host="invalid-dev-workspace-api.local"
fi

sed -e "s/__DEV_WORKSPACE_HOST__/${dev_workspace_host}/g" \
  -e "s/__DEV_WORKSPACE_API_HOST__/${dev_workspace_api_host}/g" \
  /etc/squid/squid.conf.template > /tmp/squid.conf

squid -k parse -f /tmp/squid.conf
exec squid -f /tmp/squid.conf -N -d 1
