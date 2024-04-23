# Vector

A library to embed [Vector](https://vector.dev/) agents inside Elixir applications.

## Installation

```elixir
def deps do
  [
    {:vector_agent, "~> 0.1.0"}
  ]
end
```

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
