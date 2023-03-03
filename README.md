# PHP New Relic Agent multi-platform

## Ideas

New Relic agent for `x86_x64` is ready to compile the PHP extension and getting up fast when we build Dockerfile. However, it's a pain for `arm64` architecture.
This repository purpose is to cut down the build time for everyone want to use PHP New Relic Agent by using [Multi-stage build](https://docs.docker.com/build/building/multi-stage/).

## Supported Versions

[Official New Relic Agent Supported Versions](https://docs.newrelic.com/docs/release-notes/agent-release-notes/php-release-notes)

## Usage

```Dockerfile

# Install NewRelic
COPY --from=nntoan/php-newrelic-agent:<NR_AGENT_VERSION> /newrelic-php-agent/dist/newrelic.ini /etc/php.d/newrelic.ini
COPY --from=nntoan/php-newrelic-agent:<NR_AGENT_VERSION> /newrelic-php-agent/dist/newrelic.so /usr/lib/php7/modules
COPY --from=nntoan/php-newrelic-agent:<NR_AGENT_VERSION> /newrelic-php-agent/dist/newrelic-daemon /usr/bin/newrelic-daemon
RUN mkdir -p 0777 /var/log/newrelic;
```

## License

MIT License
