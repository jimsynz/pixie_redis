defmodule Pixie.Redis.ClientTest do
  use ExUnit.Case
  use Pixie.Redis.ConnectionPool
  alias Pixie.Redis.{Client, ConnectionPool}

  @redis_key "pixie:test:client:client_pids"

  setup do
    ConnectionPool.reset!
  end

  test "`store`" do
    Client.store("client_id", self)
    with_connection(fn (redis) ->
      assert Redis.hexists(redis, @redis_key)
    end)
  end

  test "`get` when the client exists" do
    Client.store("client_id", self)
    assert Client.get("client_id") == self
  end

  test "`get` when the client doesn't exist" do
    refute Client.get("client_id")
  end

  test "`destroy`" do
    Client.store("client_id", self)
    with_connection(fn (redis) ->
      assert Redis.hget(redis, "#{@redis_key}:client_id")
    end)
    Client.destroy("client_id")
    with_connection(fn (redis) ->
      assert Redis.hget(redis, "#{@redis_key}:client_id") == :undefined
    end)
  end

  test "`exists?` when the client exists" do
    Client.store("client_id", self)
    assert Client.exists?("client_id")
  end

  test "`exists?` when the client doesn't exist" do
    refute Client.exists?("client_id")
  end
end