lager_udp_backend
=================

lager-logging upd backend with msgpack 

This is a backend for the Lager Erlang logging framework.

[https://github.com/basho/lager](https://github.com/basho/lager)

It will send all of your logging messages to an ip:port via udp. The messages will be sent msgpack_ed

### Usage

Include this backend into your project using rebar:

    {lager_udp_backend, ".*", {git, "https://github.com/LineMetrics/lager_udp_backend.git", "master"}}

### Configuration

You can pass the backend the following configuration (shown are the defaults):

    {lager, [
      {handlers, [
        {lager_udp_backend, [
          {name,        "lager_amqp_backend"},
          {level,       debug},
          {udp_host,   "localhost"},
          {udp_port,   5672}
        ]}
      ]}
    ]}

### License
Apache License 2.0
