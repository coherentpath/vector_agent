defmodule Vector.Consumer do
  @moduledoc """
  A behaviour to consume stdout and stderr from Vector.
  """

  @typedoc """
  A Vector consumer module.
  """
  @type t :: module()

  @typedoc """
  The possible types of data.
  """
  @type type :: :stdout | :stderr

  @typedoc """
  Raw data from Vector.

  This represents one or more possible events/logs based on framing configuration.
  A consumer module is responsible for splitting it based on the configured
  framing method.
  """
  @type data :: binary()

  @doc """
  A callback executed to handle Vector data.
  """
  @callback handle_data(Vector.agent(), type(), data(), keyword()) :: :ok
end
