# Game Server (Ruby)

This Ruby program simulates a naïve game server, where random players of different levels join a server for a random amount of time, through clients.

**[Coming Soon]**: Additionally, it provides gRPC and TCP socket wrappers, as a way to test networking, Protobuf, gRPC, TCP sockets, and Go channels capabilities.

## Requirements

Ruby 3.2.1, you can get it using [rbenv](https://github.com/rbenv/rbenv) with:

```bash
rbenv install 3.2.1
```

To install the dependencies, run:

```bash
bundle install
```

## Development

You can test the program locally without any remote calls with:

```bash
./bin/local_simulation
```

### Coming Soon

Otherwise you can test a client-server setup by running the server in one terminal with:

```bash
./remote_server
```

And any other number of clients in different terminal windows with:

```bash
./remote_client
```

Additionally a command to spawn 10,000 clients against the server is available with:

```bash
./remote_client_spawn
```

Be careful though, as this is quite resource-intensive and, if you over-do it, you may run out of available TCP ports on your machine :D
