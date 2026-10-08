#!/bin/sh
set -eu

config_source="${EGRESS_PROXY_CONFIG_PATH:-/etc/squid/squid.conf.template}"
cp "$config_source" /tmp/squid.conf

squid -k parse -f /tmp/squid.conf
exec squid -f /tmp/squid.conf -N -d 1
