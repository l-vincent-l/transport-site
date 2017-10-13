defmodule Transport.Worker do
  use GenServer

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: :publisher)
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: :publisher)
  end

  def validate_data(url) do
    GenServer.cast(:publisher, {:publish, "data_validations", url})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, "data_validations")
    {:ok, %{channel: channel, connection: connection} }
  end

  def handle_cast({:publish, channel, message}, state) do
    AMQP.Basic.publish(state.channel, "", channel, message)

    {:noreply, state}
  end

  def terminate(_reason, state) do
    AMQP.Connection.close(state.connection)
  end
end


