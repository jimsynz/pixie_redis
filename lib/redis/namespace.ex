defmodule Pixie.Redis.Namespace do
  use Pixie.Redis.ConnectionPool

  @moduledoc """
  Generate random IDs and store them in Redis to make sure that they're
  unique.
  """

  def generate(length) do
    with_connection(fn (redis) ->
      generate(redis, length)
    end)
  end

  def generate(redis, length) when is_pid(redis) do
    namespace = UToken.generate(length)

    if exists?(redis, namespace) do
      generate(redis, length)
    else
      Redis.sadd(redis, redis_key, namespace)
      namespace
    end
  end

  def all do
    with_connection(fn (redis) ->
      all(redis)
    end)
  end

  def all(redis) when is_pid(redis) do
    Redis.smembers(redis, redis_key)
  end

  def exists?(namespace) do
    with_connection(fn (redis) ->
      exists?(redis, namespace)
    end)
  end

  def exists?(redis, namespace) when is_pid(redis) do
    case Redis.sismember(redis, redis_key, namespace) do
      "0" -> false
      "1" -> true
    end
  end

  def release(namespace) do
    with_connection(fn (redis) ->
      release(redis, namespace)
    end)
  end

  def release(redis, namespace) when is_pid(redis) do
    Redis.srem(redis, redis_key, namespace)
  end

  defp redis_key do
    cluster_key("namespaces")
  end

end
