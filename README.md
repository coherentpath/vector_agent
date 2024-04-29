# Vector

A library to embed [Vector](https://vector.dev/) agents inside Elixir applications.

## Installation

```elixir
def deps do
  [
    {:vector_agent, "~> *.*.*"}
  ]
end
```

Please note that `curl` and `bash` must both be available during compilation in
order to download the vector agent binary.

Additionally - `:vector_agent` makes use of `:erlexec` to control vector agents.
`:erlexec` expects a `SHELL` environment variable to be available - otherwise
startup errors will occur. If this value is not already set - its common to set it with the value `/bin/sh`.

## Examples

Simple logging of demo log events from a Vector agent.

```elixir
config = %{
  sources: %{
    test_source: %{
      type: "demo_logs",
      format: "apache_common"
    }
  },
  sinks: %{
    test_sink: %{
      type: "console",
      inputs: ["test_source"],
      encoding: %{
        codec: "text"
      }
    }
  }
}

config = Jason.encode!(config)
file = File.cwd!() <> "/vector.json"
:ok = File.write!(file, config)

config = %Vector.Config{
  config: file,
  stdout: {Vector.Consumer.Logger, []}
}

{:ok, _} = Vector.start_link(config)
```

Sending events to a Vector agent that are then sent back and logged.

```elixir
config = %{
  sources: %{
    test_source: %{
      type: "stdin"
    }
  },
  sinks: %{
    test_sink: %{
      type: "console",
      inputs: ["test_source"],
      encoding: %{
        codec: "text"
      }
    }
  }
}

config = Jason.encode!(config)
file = File.cwd!() <> "/vector.json"
:ok = File.write!(file, config)

config = %Vector.Config{
  config: file,
  stdout: {Vector.Consumer.Logger, []}
}

{:ok, pid} = Vector.start_link(config)
:ok = Vector.send(pid, "Hello Vector!\n")
```
