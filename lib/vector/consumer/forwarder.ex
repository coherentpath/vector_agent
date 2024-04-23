defmodule Vector.Consumer.Forwarder do
  @moduledoc """
  A Vector consumer that forwards data to another process.

  The data will be in the format:

      {:vector_data, agent, data}
  """

  @behaviour Vector.Consumer

  @impl Vector.Consumer
  def handle_data(agent, data, pid: pid) do
    send(pid, {:vector_data, agent, data})
    :ok
  end
end
