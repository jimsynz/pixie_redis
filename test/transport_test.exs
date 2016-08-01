defmodule Pixie.Redis.TransportTest do
  use ExUnit.Case
  alias Pixie.Redis.{Transport, ConnectionPool}
  use ConnectionPool

  @redis_key "pixie:test:transports"

  setup do
    ConnectionPool.reset!
  end

  test "`store`" do
    Transport.store("transport_id", self)

    with_connection(fn (redis) ->
      assert Redis.hget(redis, @redis_key, "transport_id") == :erlang.term_to_binary(self)
    end)
  end

  test "`get` when the transport exists" do
    Transport.store("transport_id", self)
    assert Transport.get("transport_id") == self
  end

  test "`get` when the transport doesn't exist" do
    refute Transport.get("transport_id")
  end

  test "`destroy`" do
    Transport.store("transport_id", self)

    with_connection(fn (redis) ->
      assert Redis.hexists(redis, @redis_key, "transport_id") == 1
    end)

    Transport.destroy("transport_id", self)

    with_connection(fn (redis) ->
      assert Redis.hexists(redis, @redis_key, "transport_id") == 0
    end)
  end

  test "`exists?` when the transport exists" do
    Transport.store("transport_id", self)
    assert Transport.exists?("transport_id")
  end

  test "`exists?` when the transport doesn't exist" do
    refute Transport.exists?("transport_id")
  end
end
