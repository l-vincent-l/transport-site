defmodule Transport.WorkerTest do
  use ExUnit.Case

  alias AMQP.Connection
  alias AMQP.Channel
  alias AMQP.Basic
  alias Transport.Worker

  @channel_name "data-validations"

  setup do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, @channel_name)
    {:ok, %{channel: channel} }
  end

  test "basic return", meta do
    Worker.validate_data("pouet")
    AMQP.Basic.consume(meta.channel, @channel_name, nil, no_ack: true)

    assert_receive {:basic_consume_ok, _}
    assert_receive {:basic_deliver, "pouet"}
  end
end
