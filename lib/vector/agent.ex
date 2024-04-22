defmodule Vector.Agent do
  @moduledoc """
  A module for running a Vector agent.
  """

  use GenServer

  require Logger

  defstruct [:config, :pid, :os_pid]

  ################################
  # Public API
  ################################

  @doc """
  Starts a new Vector agent.
  """
  @spec start_link(Vector.Config.t()) :: GenServer.on_start()
  def start_link(config) do
    GenServer.start_link(__MODULE__, config)
  end

  @doc """
  Stops a running Vector agent.
  """
  @spec stop(GenServer.server()) :: :ok
  def stop(agent), do: GenServer.stop(agent)

  ################################
  # GenServer Callbacks
  ################################

  @impl GenServer
  def init(config) do
    Process.flag(:trap_exit, true)
    {:ok, config, {:continue, :start}}
  end

  @impl GenServer
  def handle_continue(:start, config) do
    agent = do_start(config)
    do_log(:info, agent, "vector: Vector is starting.")
    {:noreply, agent}
  end

  @impl GenServer
  def handle_info({:stdout, _, message}, agent) do
    handle_stdout(agent, message)
    {:noreply, agent}
  end

  def handle_info({:stderr, _, message}, agent) do
    handle_stderr(agent, message)
    {:noreply, agent}
  end

  def handle_info({:EXIT, _, {:exit_status, _} = status}, agent) do
    {:stop, {:vector_error, status}, agent}
  end

  def handle_info({:EXIT, _, :normal}, agent) do
    {:stop, :normal, agent}
  end

  @impl GenServer
  def terminate({:vector_error, {:exit_status, status}}, agent) do
    do_log(:error, agent, "vector: Vector is exiting with error status #{status}.")
    agent
  end

  def terminate(:normal, agent) do
    :exec.stop(agent.os_pid)
    do_log(:info, agent, "vector: Vector is stopping.")
    agent
  end

  ################################
  # Private API
  ################################

  defp do_start(config) do
    options = build_options(config)
    command = Vector.start_command(config)
    {:ok, pid, os_pid} = :exec.run_link(command, options)
    %__MODULE__{config: config, pid: pid, os_pid: os_pid}
  end

  defp build_options(config) do
    [{:stderr, self()}]
    |> with_option(config, :stdout)
  end

  defp with_option(options, config, :stdout) do
    case config.consumers do
      [_ | _] ->
        options ++ [{:stdout, self()}]

      _ ->
        options
    end
  end

  defp handle_stdout(agent, message) do
    events = parse_message(message)

    for {consumer, opts} <- agent.config.consumers do
      consumer.handle_events(agent, events, opts)
    end
  end

  defp handle_stderr(agent, message) do
    logs = parse_message(message)
    handle_logs(agent, logs)
  end

  defp handle_logs(_agent, []), do: :ok

  defp handle_logs(agent, [log | logs]) do
    case log do
      <<_dt::binary-size(27), "  INFO "::binary, msg::binary>> ->
        do_log(:info, agent, msg)

      <<_dt::binary-size(27), "  WARN "::binary, msg::binary>> ->
        do_log(:warning, agent, msg)

      <<_dt::binary-size(27), " ERROR "::binary, msg::binary>> ->
        do_log(:error, agent, msg)

      <<_dt::binary-size(27), " DEBUG "::binary, msg::binary>> ->
        do_log(:debug, agent, msg)
    end

    handle_logs(agent, logs)
  end

  defp parse_message(message) do
    :binary.split(message, "\n", [:global, :trim])
  end

  defp do_log(level, agent, msg) do
    Logger.log(level, ["[", inspect(agent), "]", " ", msg])
  end

  defimpl Inspect do
    def inspect(%{os_pid: os_pid}, _) do
      "#Vector.Agent<pid: #{inspect(os_pid)}>"
    end
  end
end
