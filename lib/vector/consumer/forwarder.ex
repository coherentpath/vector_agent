defmodule Vector.Consumer.Forwarder do
  @moduledoc """
  A Vector consumer that forwards events to another process.

  The events will be in the format:

      {:vector_events, agent, events}
  """

  @behaviour Vector.Consumer

  @impl Vector.Consumer
  def handle_events(_agent, [], _opts), do: :ok

  def handle_events(agent, events, pid: pid) do
    send(pid, {:vector_events, agent, events})
    :ok
  end
end
