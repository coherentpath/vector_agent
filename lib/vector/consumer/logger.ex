defmodule Vector.Consumer.Logger do
  @moduledoc """
  A Vector consumer that logs events.
  """

  @behaviour Vector.Consumer

  require Logger

  @impl Vector.Consumer
  def handle_events(_agent, [], _opts), do: :ok

  def handle_events(agent, [event | events], opts) do
    :ok = Logger.info(event)
    handle_events(agent, events, opts)
  end
end
