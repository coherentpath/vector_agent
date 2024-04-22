defmodule Vector.Consumer do
  @moduledoc """
  A behaviour to consume events from Vector.
  """

  @typedoc """
  A Vector consumer module.
  """
  @type t :: module()

  @doc """
  A callback executed to handle Vector events.
  """
  @callback handle_events(Vector.Agent.t(), [binary()], keyword()) :: :ok
end
