defmodule Vector.Agent do
  @moduledoc false

  use GenServer

  alias Vector.Consumer.Logger

  defstruct [:config, :pid, :os_pid]

  ################################
  # Public API
  ################################

  @doc false
  @spec start_link(Vector.Config.t()) :: GenServer.on_start()
  def start_link(%Vector.Config{} = config) do
    GenServer.start_link(__MODULE__, config)
  end

  @doc false
  @spec stop(GenServer.server()) :: :ok
  def stop(agent) do
    GenServer.stop(agent)
  end

  @doc false
  @spec send(GenServer.server(), data :: iodata()) :: :ok
  def send(agent, data) do
    data = to_string(data)
    GenServer.call(agent, {:send, data})
  end

  ################################
  # GenServer Callbacks
  ################################

  @impl GenServer
  def init(config) do
    Process.flag(:trap_exit, true)

    if config.start_async do
      {:ok, config, {:continue, :start}}
    else
      agent = do_start(config)
      {:ok, agent}
    end
  end

  @impl GenServer
  def handle_continue(:start, config) do
    agent = do_start(config)
    {:noreply, agent}
  end

  @impl GenServer
  def handle_call({:send, data}, _from, agent) do
    :ok = :exec.send(agent.os_pid, data)
    {:reply, :ok, agent}
  end

  @impl GenServer
  def handle_info({:stdout, _, stdout}, agent) do
    handle_data(agent, :stdout, stdout)
    {:noreply, agent}
  end

  def handle_info({:stderr, _, stderr}, agent) do
    handle_data(agent, :stderr, stderr)
    {:noreply, agent}
  end

  def handle_info({:EXIT, _, {:exit_status, _} = status}, agent) do
    {:stop, {[:vector, :error], status}, agent}
  end

  def handle_info({:EXIT, _, :normal}, agent) do
    {:stop, :normal, agent}
  end

  def handle_info(:shutdown, agent) do
    {:stop, :normal, agent}
  end

  @impl GenServer
  def terminate({[:vector, :error], {:exit_status, status}}, agent) do
    :ok = Logger.log(agent, :error, "vector: Vector is exiting with error status #{status}.")
    agent
  end

  def terminate(message, agent) when message in [:normal, :shutdown] do
    :ok = Logger.log(agent, :info, "vector: Vector is stopping.")
    :ok = :exec.stop(agent.os_pid)
    do_confirm_exit(agent)
    do_flush_messages(agent)
    :ok = Logger.log(agent, :info, "vector: Vector has stopped.")
    agent
  end

  ################################
  # Private API
  ################################

  defp do_start(config) do
    options = build_options(config)
    command = Vector.start_command(config)
    {:ok, pid, os_pid} = :exec.run_link(command, options)
    agent = %__MODULE__{config: config, pid: pid, os_pid: os_pid}
    :ok = Logger.log(agent, :info, "vector: Vector is starting.")
    maybe_schedule_shutdown(agent)
    agent
  end

  defp build_options(config) do
    [:stdin]
    |> with_option(config, :stdout)
    |> with_option(config, :stderr)
  end

  defp with_option(options, config, option) when option in [:stderr, :stdout] do
    case Map.get(config, option) do
      {_, _} -> options ++ [option]
      _ -> options
    end
  end

  defp handle_data(agent, type, data) do
    {consumer, opts} = Map.get(agent.config, type)
    consumer.handle_data(agent, type, data, opts)
  end

  defp maybe_schedule_shutdown(agent) do
    if is_integer(agent.config.shutdown_ms) do
      :ok =
        Logger.log(
          agent,
          :info,
          "vector: Vector shutdown scheduled in #{agent.config.shutdown_ms}ms."
        )

      Process.send_after(self(), :shutdown, agent.config.shutdown_ms)
    end
  end

  defp do_confirm_exit(agent) do
    case System.cmd("kill", ["-0", to_string(agent.os_pid)], stderr_to_stdout: true) do
      {_, 0} ->
        :timer.sleep(100)
        do_confirm_exit(agent)

      {_, 1} ->
        :ok
    end
  end

  defp do_flush_messages(agent) do
    receive do
      msg -> handle_info(msg, agent)
    after
      0 -> :ok
    end
  end

  defimpl Inspect do
    def inspect(%{os_pid: os_pid}, _) do
      "#Vector.Agent<pid: #{inspect(os_pid)}>"
    end
  end
end
