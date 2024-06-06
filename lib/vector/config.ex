defmodule Vector.Config do
  @moduledoc """
  A module to manage Vector configuration.
  """

  defstruct [
    :stdout,
    :config,
    :require_healthy,
    :threads,
    :verbose,
    :quiet,
    :watch_config,
    :internal_log_rate_limit,
    :graceful_shutdown_limit_secs,
    :no_graceful_shutdown_limit,
    :allocation_tracing,
    :allocation_tracing_reporting_interval_ms,
    :openssl_no_probe,
    :allow_empty_config,
    :strict_env_vars,
    :log_level,
    start_async: true,
    stderr: {Vector.Consumer.Logger, []}
  ]

  @typedoc """
  A Vector configuration struct.
  """
  @type t :: %__MODULE__{
          stdout: {Vector.Consumer.t(), keyword()} | nil,
          stderr: {Vector.Consumer.t(), keyword()} | nil,
          config: binary(),
          require_healthy: boolean() | nil,
          threads: integer() | nil,
          verbose: boolean() | nil,
          quiet: boolean() | nil,
          watch_config: boolean() | nil,
          internal_log_rate_limit: integer() | nil,
          graceful_shutdown_limit_secs: integer() | nil,
          no_graceful_shutdown_limit: integer() | nil,
          allocation_tracing: boolean() | nil,
          allocation_tracing_reporting_interval_ms: integer() | nil,
          openssl_no_probe: boolean() | nil,
          allow_empty_config: boolean() | nil,
          strict_env_vars: boolean() | nil,
          log_level: :trace | :debug | :info | :warn | :error | :none | nil,
          start_async: boolean()
        }

  ################################
  # Public API
  ################################

  @doc """
  Converts configuration into Vector args.
  """
  @spec to_args(t()) :: binary()
  def to_args(%__MODULE__{} = config) do
    config = Map.from_struct(config)
    config = Enum.reduce(config, [], &to_args/2)
    to_string(config)
  end

  ################################
  # Private API
  ################################

  defp to_args({:config, config}, args) when is_binary(config) do
    ["--config", " ", config, " " | args]
  end

  defp to_args({:threads, threads}, args) when is_integer(threads) do
    ["--threads", " ", to_string(threads), " " | args]
  end

  defp to_args({:verbose, true}, args) do
    ["--verbose", " " | args]
  end

  defp to_args({:quiet, true}, args) do
    ["--quiet", " " | args]
  end

  defp to_args({:watch_config, true}, args) do
    ["--watch-config", " " | args]
  end

  defp to_args({:internal_log_rate_limit, limit}, args) when is_integer(limit) do
    ["--internal-log-rate-limit", " ", to_string(limit), " " | args]
  end

  defp to_args({:graceful_shutdown_limit_secs, limit}, args) when is_integer(limit) do
    ["--graceful-shutdown-limit-secs", " ", to_string(limit), " " | args]
  end

  defp to_args({:no_graceful_shutdown_limit, true}, args) do
    ["--graceful-shutdown-limit-secs", " " | args]
  end

  defp to_args({:strict_env_vars, true}, args) do
    ["--strict-env-vars", " " | args]
  end

  defp to_args({:allow_empty_config, true}, args) do
    ["--allow-empty-config", " " | args]
  end

  defp to_args({:require_healthy, true}, args) do
    ["--require-healthy", " ", "true", " " | args]
  end

  defp to_args({:log_level, level}, args) when is_atom(level) do
    case level do
      :debug -> ["-v", " " | args]
      :trace -> ["-vv", " " | args]
      :warn -> ["-q", " " | args]
      :error -> ["-qq", " " | args]
      :none -> ["-qqq", " " | args]
      _ -> args
    end
  end

  defp to_args(_, args), do: args
end
