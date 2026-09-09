# Squid Egress Proxy for Admiral Network Lockdown
# Restricts outbound HTTP/HTTPS traffic to allowlisted domains only
#
# This proxy runs alongside the opencode container and enforces strict
# network egress controls. All HTTP/HTTPS traffic from opencode must
# pass through this proxy.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    squid \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create log and run directories with proper permissions
RUN mkdir -p /var/log/squid /var/spool/squid /var/run/squid \
    && chown -R proxy:proxy /var/log/squid /var/spool/squid /var/run/squid

# Copy configuration
COPY squid.conf /etc/squid/squid.conf.template
COPY start-squid.sh /usr/local/bin/start-squid.sh
RUN chmod 755 /usr/local/bin/start-squid.sh

# Expose Squid port
EXPOSE 3128

# Run as proxy user for security
USER proxy

# Start Squid with rendered config in foreground mode
CMD ["/usr/local/bin/start-squid.sh"]
