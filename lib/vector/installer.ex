defmodule Vector.Installer do
  @moduledoc """
  A module to manage installing a Vector binary on the system.

  Installation will automatically happen at compile time. By default,
  the latest version of the Vector binary will be installed. Alternatively
  a version can be specified in a `VECTOR_VERSION` environment variable.
  """

  require Logger

  @install """
  curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash -s -- -y --prefix {path}
  """

  ################################
  # Module Callbacks
  ################################

  @after_compile __MODULE__

  def __after_compile__(_env, _bytecode), do: run!()

  ################################
  # Public API
  ################################

  @doc """
  Runs the Vector installer.

  This will install the latest version of Vector or whatever version
  is specified in a `VECTOR_VERSION` environment variable.
  """
  @spec run! :: :ok
  def run! do
    if installed?() do
      Logger.debug("Vector install skipping.")
      :ok
    else
      Logger.debug("Vector binary downloading...")
      install!()
      :ok
    end
  end

  ################################
  # Private API
  ################################

  defp installed? do
    case Vector.version() do
      {:ok, version} ->
        Logger.debug("Vector #{version} installed.")
        true

      :error ->
        false
    end
  end

  defp install! do
    path = Vector.install_path()
    install = String.replace(@install, "{path}", path)
    install = String.to_charlist(install)
    # credo:disable-for-next-line
    debug_info = :os.cmd(install)
    validate!(debug_info)
  end

  defp validate!(debug_info) do
    case Vector.version() do
      {:ok, version} ->
        Logger.debug("Vector #{version} installed.")
        :ok

      :error ->
        IO.puts(debug_info)
        raise RuntimeError, "Vector binary failed to install."
    end
  end
end
