defmodule Vector.Consumer.Telemetry do
  @moduledoc """
  A Vector consumer that emits telemetry.

  ## Events

  * `[:vector, :stdout]` - Called when stdout data is recieved by an agent.

    #### Measurements
      * `:system_time` - The current monotonic system time.

    #### Metadata
      * `:agent` - A `t:Vector.agent/0` struct.
      * `:data` - A binary of the stdout recieved. This could be one or more
      events based on framing configuration.
      * `:opts` - A keyword list of options passed to an agent when the consumer
      is configured.

  * `[:vector, :stderr]` - Called when stderr data is recieved by an agent.

    #### Measurements
      * `:system_time` - The current monotonic system time.

    #### Metadata
      * `:agent` - A `t:Vector.agent/0` struct.
      * `:data` - A binary of the stderr recieved. This could be one or more
      logs based on framing configuration.
      * `:opts` - A keyword list of options passed to an agent when the consumer
      is configured.
  """

  @behaviour Vector.Consumer

  ################################
  # Vector.Consumer Callbacks
  ################################

  @impl Vector.Consumer
  def handle_data(agent, type, data, opts) do
    measurements = %{system_time: System.system_time()}
    metadata = %{agent: agent, data: data, opts: opts}
    :ok = :telemetry.execute([:vector, type], measurements, metadata)
  end
end
