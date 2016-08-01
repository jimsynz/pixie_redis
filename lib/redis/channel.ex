defmodule Pixie.Redis.Channel do
  use Pixie.Redis.ConnectionPool

  @moduledoc """
  Store and retrieve Channel matchers in Redis.
  """

  def store(channel_name) do
    with_connection(fn (redis) ->
      value =
        channel_name
        |> ExMinimatch.compile
        |> :erlang.term_to_binary

      Redis.hset(redis, key, channel_name, value)
    end)
  end

  def get(channel_name) do
    with_connection(fn (redis) ->
      redis
      |> Redis.hget(key, channel_name)
      |> :erlang.binary_to_term
    end)
  end

  def destroy(channel_name) do
    with_connection(fn (redis) ->
      Redis.hdel(redis, key, channel_name)
    end)
  end

  def list do
    with_connection(fn (redis) ->
      list(redis)
    end)
  end

  def list(redis) when is_pid(redis) do
    redis
    |> Redis.hgetall(key)
    |> Enum.map(fn ({key, value}) ->
      {key, :erlang.binary_to_term(value)}
    end)
  end

  def exists?(channel_name) do
    with_connection(fn (redis) ->
      case Redis.hexists(redis, key, channel_name) do
        0 -> false
        1 -> true
      end
    end)
  end

  def match(channel_name) do
    list
    |> Enum.filter_map(
      fn {_, matcher} -> ExMinimatch.match(matcher, channel_name) end,
      fn {name, _}    -> name end
    )
  end

  defp key do
    cluster_key("channels")
  end
end