defmodule Vector.Consumer.Logger do
  @moduledoc """
  A Vector consumer that logs data.
  """

  @behaviour Vector.Consumer

  require Logger

  @impl Vector.Consumer
  def handle_data(agent, data, _opts) do
    :ok = Logger.info([inspect(agent), ": ", data])
  end
end
