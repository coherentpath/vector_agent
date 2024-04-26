defmodule Vector.Logger do
  @moduledoc false

  require Logger

  ################################
  # Public API
  ################################

  @doc false
  @spec log(Vector.agent(), Logger.level(), iodata()) :: :ok
  def log(agent, level, msg) do
    Logger.log(level, ["[", inspect(agent), "]", " ", msg])
  end

  @doc false
  @spec log_stderr(Vector.agent(), binary()) :: :ok
  def log_stderr(agent, raw) do
    logs = parse_stderr(raw)
    Enum.each(logs, fn {level, log} -> log(agent, level, log) end)
  end

  @doc false
  @spec parse_stderr(binary()) :: [{Logger.level(), iodata()}]
  def parse_stderr(raw) do
    parts = :binary.split(raw, "\n", [:global, :trim])
    parts = parse_parts(parts, [])
    {_, logs} = Enum.reduce(parts, {[], []}, &parts_to_logs/2)
    logs
  end

  ################################
  # Private API
  ################################

  defp parse_parts([], parsed_parts), do: parsed_parts

  defp parse_parts([part | parts], parsed_parts) do
    parsed_part =
      case part do
        <<_dt::binary-size(27), "  INFO "::binary, msg::binary>> ->
          {:log, :info, msg}

        <<_dt::binary-size(27), "  WARN "::binary, msg::binary>> ->
          {:log, :warning, msg}

        <<_dt::binary-size(27), " ERROR "::binary, msg::binary>> ->
          {:log, :error, msg}

        <<_dt::binary-size(27), " DEBUG "::binary, msg::binary>> ->
          {:log, :debug, msg}

        <<_dt::binary-size(27), " TRACE "::binary, msg::binary>> ->
          {:log, :debug, msg}

        "" ->
          :skip

        msg ->
          {:msg, msg}
      end

    parse_parts(parts, [parsed_part | parsed_parts])
  end

  defp parts_to_logs({:log, level, msg}, {parts, logs}) do
    {[], [{level, to_string([msg | parts])} | logs]}
  end

  defp parts_to_logs({:msg, msg}, {parts, logs}) do
    {[" ", msg | parts], logs}
  end

  defp parts_to_logs(_, {parts, logs}), do: {parts, logs}
end
