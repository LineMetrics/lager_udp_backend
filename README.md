lager_udp_backend
=================

lager udp-backend with msgpack 

This is a backend for the Lager Erlang logging framework.

[https://github.com/basho/lager](https://github.com/basho/lager)

It will send all of your logging messages to an ip:port via udp. The messages will be sent msgpack_ed

### Usage

Include this backend into your project using rebar:

    {lager_udp_backend, ".*", {git, "https://github.com/LineMetrics/lager_udp_backend.git", "master"}}

### Configuration

You can pass the backend the following configuration :

    {lager, [
      {handlers, [
        {lager_udp_backend, [
          {name,        "lager_udp_backend"},
          {level,       debug},
          {host,    "localhost"},
          {port,    4712}
        ]}
      ]}
    ]}

### License
Apache License 2.0
