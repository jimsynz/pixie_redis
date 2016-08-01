defmodule Pixie.Redis.ChannelTest do
  use ExUnit.Case
  alias Pixie.Redis.{Channel, ConnectionPool}
  use ConnectionPool

  @redis_key "pixie:test:channels"

  setup do
    ConnectionPool.reset!
  end

  test "`store`" do
    Channel.store("channel_name")
    with_connection(fn (redis) ->
      assert Redis.hexists(redis, @redis_key)
    end)
  end

  test "`destroy`" do
    Channel.store("channel_name")
    Channel.destroy("channel_name")
    with_connection(fn (redis) ->
      assert Redis.hexists(redis, @redis_key) == 0
    end)
  end

  test "`exists?` when the channel exists" do
    Channel.store("channel_name")
    assert Channel.exists?("channel_name")
  end

  test "`exists?` when the channel doesn't exist" do
    refute Channel.exists?("channel_name")
  end
end