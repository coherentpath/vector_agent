defmodule Vector do
  @moduledoc """
  A module for managing an embedded [Vector](https://vector.dev/) agent.
  """

  ################################
  # Public API
  ################################

  @doc """
  Starts a new Vector agent.
  """
  @spec start_link(Vector.Config.t()) :: GenServer.on_start()
  defdelegate start_link(config), to: Vector.Agent

  @doc """
  Returns a specification to start a Vector agent under a supervisor.
  See `Supervisor`.
  """
  @spec child_spec(Vector.Config.t()) :: Supervisor.child_spec()
  defdelegate child_spec(config), to: Vector.Agent

  @doc """
  Stops a running Vector agent.
  """
  @spec stop(GenServer.server()) :: :ok
  defdelegate stop(agent), to: Vector.Agent

  @doc """
  Returns the Vector binary path.
  """
  @spec binary_path :: String.t()
  def binary_path do
    to_string([install_path(), "/bin/vector"])
  end

  @doc """
  Returns the Vector install path.
  """
  @spec install_path :: String.t()
  def install_path do
    to_string(:code.priv_dir(:vector_agent))
  end

  @doc """
  Returns the Vector start command.
  """
  @spec start_command(Vector.Config.t()) :: binary()
  def start_command(config) do
    args = Vector.Config.to_args(config)
    to_string([binary_path(), " ", args])
  end

  @doc """
  Returns the Vector version.
  """
  @spec version :: {:ok, Version.t()} | :error
  def version do
    with {:ok, version} <- cmd(["--version"]) do
      parts = String.split(version, " ")
      [_, version | _] = parts
      version = Version.parse!(version)
      {:ok, version}
    end
  end

  ################################
  # Private API
  ################################

  defp cmd(args) when is_list(args) do
    case System.cmd(binary_path(), args) do
      {result, 0} -> {:ok, result}
      _ -> :error
    end
  rescue
    ErlangError -> :error
  end
end
