defmodule VectorTest do
  use ExUnit.Case

  @moduletag :capture_log

  alias Vector.Consumer.Forwarder

  test "will start a vector agent" do
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

    config = %Vector.Config{
      config: write_config(config),
      consumers: [{Forwarder, [pid: self()]}]
    }

    assert {:ok, _} = Vector.start_link(config)
    assert_receive {:vector_events, _agent, events}, 1_000
    assert [_] = events
  end

  test "will exit if passed bad config" do
    config = %Vector.Config{
      config: write_config(%{})
    }

    Process.flag(:trap_exit, true)

    assert {:ok, pid} = Vector.start_link(config)
    assert_receive {:EXIT, ^pid, {:vector_error, {:exit_status, 19_968}}}, 1_000
  end

  test "will recieve data via stdin" do
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

    config = %Vector.Config{
      config: write_config(config),
      consumers: [{Forwarder, [pid: self()]}]
    }

    assert {:ok, pid} = Vector.start_link(config)
    assert :ok = Vector.send(pid, "foo\n")
    assert_receive {:vector_events, _agent, events}, 1_000
    assert ["foo"] = events
  end

  defp write_config(config) do
    file = Enum.random(1..100_000)
    file = System.tmp_dir!() <> "/#{file}.json"
    config = Jason.encode!(config)
    :ok = File.write!(file, config)
    file
  end
end
