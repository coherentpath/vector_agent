defmodule Vector.Consumer do
  @moduledoc """
  A behaviour to consume data from Vector.
  """

  @typedoc """
  A Vector consumer module.
  """
  @type t :: module()

  @typedoc """
  Raw data from Vector.
  """
  @type data :: binary()

  @doc """
  A callback executed to handle Vector data.

  Data represents one or more possible events based on framing configuration.
  A consumer module is responsible for splitting data based on the configured
  framing method.
  """
  @callback handle_data(Vector.agent(), data(), keyword()) :: :ok
end
