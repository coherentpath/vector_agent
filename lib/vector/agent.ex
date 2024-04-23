defmodule Vector.Agent do
  @moduledoc false

  use GenServer

  require Logger

  defstruct [:config, :pid, :os_pid]

  @typedoc """
  A running Vector agent.
  """
  @type t :: %Vector.Agent{
          config: Vector.Config.t(),
          pid: pid(),
          os_pid: non_neg_integer()
        }

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
    {:ok, config, {:continue, :start}}
  end

  @impl GenServer
  def handle_continue(:start, config) do
    agent = do_start(config)
    do_log(:info, agent, "vector: Vector is starting.")
    {:noreply, agent}
  end

  @impl GenServer
  def handle_call({:send, data}, _from, agent) do
    :ok = :exec.send(agent.os_pid, data)
    {:reply, :ok, agent}
  end

  @impl GenServer
  def handle_info({:stdout, _, data}, agent) do
    handle_stdout(agent, data)
    {:noreply, agent}
  end

  def handle_info({:stderr, _, data}, agent) do
    handle_stderr(agent, data)
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

  def terminate(message, agent) when message in [:normal, :shutdown] do
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
    [:stderr, :stdin]
    |> with_option(config, :stdout)
  end

  defp with_option(options, config, :stdout) do
    case config.stdout do
      {_, _} ->
        options ++ [:stdout]

      _ ->
        options
    end
  end

  defp handle_stdout(agent, data) do
    {consumer, opts} = agent.config.stdout
    consumer.handle_data(agent, data, opts)
  end

  defp handle_stderr(agent, data) do
    log = String.replace(data, ["\n\n", "\n"], " ", global: true)

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
