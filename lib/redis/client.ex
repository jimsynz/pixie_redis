defmodule Pixie.Redis.Client do
  use Pixie.Redis.ConnectionPool

  @default_timeout 25_000 # 25 seconds.

  @moduledoc """
  Store and retrieve Client pids with Redis.
  """

  def store(client_id, pid) when is_pid(pid) do
    with_connection(fn (redis) ->
      value =
        pid
        |> :erlang.term_to_binary

      do_ping(redis, client_id)
      Redis.hset(redis, pid_key, client_id, value)
    end)
  end

  def get(client_id) do
    with_connection(fn (redis) ->
      do_ping(redis, client_id)
      case Redis.hget(redis, pid_key, client_id) do
        :undefined -> nil
        term       -> :erlang.binary_to_term(term)
      end
    end)
  end

  def destroy(client_id) when is_binary(client_id) do
    destroy(client_id, nil)
  end

  def destroy(client_id, _reason) when is_binary(client_id) do
    with_connection(fn (redis) ->
      destroy(redis, client_id)
    end)
  end

  def destroy(redis, client_id) when is_pid(redis) and is_binary(client_id) do
    Redis.zrem(redis, alive_key, client_id)
    Redis.hdel(redis, pid_key, client_id)
  end

  def ping(client_id) do
    with_connection(fn (redis) ->
      do_ping(redis, client_id)
    end)
  end

  def exists?(client_id) do
    with_connection(fn (redis) ->
      exists?(redis, client_id)
    end)
  end

  def exists?(redis, client_id) when is_pid(redis) do
    alive?(redis, client_id) && pid?(redis, client_id)
  end

  def list do
    {all_clients, alive_clients} = with_connection(fn (r) ->
      all   = Redis.hgetall(r, pid_key)
      alive = MapSet.new(Redis.zrangebyscore(r, alive_key, cutoff, "+inf"))
      {all, alive}
    end)

    all_clients
    |> Enum.filter_map(
      # filter
      fn ({client_id, _pid}) ->
        MapSet.member? alive_clients, client_id
      end,

      # map
      fn ({client_id, pid}) ->
        { client_id, :erlang.binary_to_term(pid) }
      end
    )
  end

  def alive?(client_id) do
    with_connection(fn (redis) ->
      alive?(redis, client_id)
    end)
  end

  def alive?(redis, client_id) when is_pid(redis) do
    case Redis.zscore(redis, alive_key, client_id) do
      ts when is_binary(ts) ->
        ts = String.to_integer(ts)
        ts >= cutoff
      _ -> false
    end
  end

  def pid?(client_id) do
    with_connection(fn (redis) ->
      pid?(redis, client_id)
    end)
  end

  def pid?(redis, client_id) when is_pid(redis) do
    case Redis.hexists(redis, pid_key, client_id) do
      0 -> false
      _ -> true
    end
  end

  defp pid_key do
    cluster_key("client_pids")
  end

  defp alive_key do
    cluster_key("alive_clients")
  end

  defp now do
    DateTime.utc_now
    |> DateTime.to_unix(:microseconds)
  end

  defp do_ping(redis, client_id) do
    Redis.zadd(redis, alive_key, now, client_id)
  end

  defp cutoff do
    trunc(now - (Pixie.Redis.timeout * 1.6 * 1_000))
  end

end
