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
      config: to_json_file!(config),
      stdout: {Forwarder, [pid: self()]}
    }

    assert {:ok, _} = Vector.start_link(config)
    assert_receive {[:vector, :stdout], _agent, stdout}, 5_000
    assert is_binary(stdout)
  end

  test "will exit if passed bad config" do
    config = %Vector.Config{
      config: to_json_file!(%{})
    }

    Process.flag(:trap_exit, true)

    assert {:ok, pid} = Vector.start_link(config)
    assert_receive {:EXIT, ^pid, {[:vector, :error], {:exit_status, 19_968}}}, 5_000
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
      config: to_json_file!(config),
      stdout: {Forwarder, [pid: self()]}
    }

    assert {:ok, pid} = Vector.start_link(config)
    assert :ok = Vector.send(pid, ["foo", "\n"])
    assert_receive {[:vector, :stdout], _agent, stdout}, 5_000
    assert stdout == "foo\n"
  end

  test "will shutdown based on shutdown_ms" do
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
      config: to_json_file!(config),
      shutdown_ms: 250
    }

    assert {:ok, pid} = Vector.start_link(config)
    assert Process.alive?(pid)

    :timer.sleep(1500)

    refute Process.alive?(pid)
  end

  defp to_json_file!(config) do
    file = Enum.random(1..100_000)
    file = System.tmp_dir!() <> "/#{file}.json"
    config = Jason.encode!(config)
    :ok = File.write!(file, config)
    on_exit(fn -> File.rm!(file) end)
    file
  end
end
