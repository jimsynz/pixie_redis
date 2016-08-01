defmodule Pixie.Redis.Transport do
  use Pixie.Redis.ConnectionPool

  @moduledoc """
  Store and retrieve transports from Redis.
  """

  def store(transport_id, transport) do
    with_connection(fn (redis) ->
      value =
        transport
        |> :erlang.term_to_binary

      Redis.hset(redis, key, transport_id, value)
    end)
  end

  def get(transport_id) do
    with_connection(fn (redis) ->
      case Redis.hget(redis, key, transport_id) do
        :undefined -> nil
        term       -> :erlang.binary_to_term(term)
      end
    end)
  end

  def destroy(transport_id, pid) do
    encoded_pid = :erlang.term_to_binary(pid)
    with_connection(fn (redis) ->
      case Redis.hget(redis, key, transport_id) do
        term when term == encoded_pid ->
          Redis.hdel(redis, key, transport_id)
        _ ->
          nil
      end
    end)
  end

  def exists?(transport_id) do
    with_connection(fn (redis) ->
      case Redis.hexists(redis, key, transport_id) do
        1 -> true
        0 -> false
      end
    end)
  end

  def list do
    with_connection(fn (redis) ->
      redis
      |> Redis.hgetall(key)
      |> Enum.map(fn ({key, value}) ->
        {key, :erlang.binary_to_term(value)}
      end)
    end)
  end

  defp key do
    cluster_key("transports")
  end

end