defmodule Vector.Consumer do
  @moduledoc """
  A behaviour to consume events from Vector.
  """

  @typedoc """
  A Vector consumer module.
  """
  @type t :: module()

  @typedoc """
  A Vector event.
  """
  @type event :: binary()

  @doc """
  A callback executed to handle Vector events.
  """
  @callback handle_events(Vector.Agent.t(), [event()], keyword()) :: :ok
end
