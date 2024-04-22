defmodule Vector.Consumer.Telemetry do
  @moduledoc """
  A Vector consumer that emits telemetry events.
  """

  @behaviour Vector.Consumer

  @impl Vector.Consumer
  def handle_events(_agent, [], _opts), do: :ok

  def handle_events(agent, [event | events], opts) do
    :ok = :telemetry.execute([:vector, :event], %{event: event}, %{agent: agent})
    handle_events(agent, events, opts)
  end
end
