defmodule Vector.Consumer.Forwarder do
  @moduledoc """
  A Vector consumer that forwards stdout and stderr to another process.

  The data will be in the format:

      {[:vector, :stdout], agent, stdout}
      {[:vector, :stderr], agent, stderr}
  """

  @behaviour Vector.Consumer

  ################################
  # Vector.Consumer Callbacks
  ################################

  @impl Vector.Consumer
  def handle_data(agent, type, data, pid: pid) do
    send(pid, {[:vector, type], agent, data})
    :ok
  end
end
