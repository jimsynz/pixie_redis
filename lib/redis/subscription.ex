defmodule Pixie.Redis.Subscription do
  use Pixie.Redis.ConnectionPool

  @moduledoc """
  Store active channel subscriptions in Redis.
  """

  def create(client_id, channel_name) do
    with_connection(fn (redis) ->
      Redis.multi(redis)
      Redis.sadd(redis, active_clients_key, client_id)
      Redis.sadd(redis, active_channels_key, channel_name)
      Redis.sadd(redis, client_key(client_id), channel_name)
      Redis.sadd(redis, channel_key(channel_name), client_id)
      Redis.exec(redis)
    end)
  end

  def destroy(client_id, channel_name) do
    with_connection(fn (redis) ->
      Redis.srem(redis, client_key(client_id), channel_name)
      Redis.srem(redis, channel_key(channel_name), client_id)

      if number_of_active_channels_for(redis, client_id) == 0 do
        Redis.srem(redis, active_clients_key, client_id)
      end

      if number_of_active_clients_for(redis, channel_name) == 0 do
        Redis.srem(redis, active_channels_key, channel_name)
      end
    end)
  end

  def clients_on(channel_name) do
    with_connection(fn (redis) ->
      clients_on(redis, channel_name)
    end)
  end

  def clients_on(redis, channel_name) when is_pid(redis) do
    redis
    |> Redis.smembers(channel_key(channel_name))
    |> MapSet.new
  end

  def channels_on(client_id) do
    with_connection(fn (redis) ->
      channels_on(redis, client_id)
    end)
  end

  def channels_on(redis, client_id) when is_pid(redis) do
    redis
    |> Redis.smembers(client_key(client_id))
    |> MapSet.new
  end

  def exists?(client_id, channel_name) do
    with_connection(fn (redis) ->
      client_member?(redis, client_id, channel_name) &&
      channel_member?(redis, channel_name, client_id)
    end)
  end

  def list do
    with_connection(fn (redis) ->
      list(redis)
    end)
  end

  def list(redis) when is_pid(redis) do
    MapSet.new
    |> active_subscriptions_by_channels(redis)
    |> active_subscriptions_by_client(redis)
    |> Enum.map(fn (tuple) -> {tuple, nil} end)
    |> Enum.to_list
  end

  defp active_subscriptions_by_channels(result_set, redis) when is_pid(redis) do
    redis
    |> Redis.smembers(active_channels_key)
    |> Enum.reduce(result_set, fn (channel_name, set) ->
      redis
      |> Redis.smembers(channel_key(channel_name))
      |> Enum.reduce(set, fn (client_id, set) ->
        MapSet.put(set, {client_id, channel_name})
      end)
    end)
  end

  defp active_subscriptions_by_client(result_set, redis) when is_pid(redis) do
    redis
    |> Redis.smembers(active_clients_key)
    |> Enum.reduce(result_set, fn (client_id, set) ->
      redis
      |> Redis.smembers(client_key(client_id))
      |> Enum.reduce(set, fn (channel_name, set) ->
        MapSet.put(set, {client_id, channel_name})
      end)
    end)
  end

  defp number_of_active_channels_for(redis, client_id) when is_pid(redis) do
    redis
    |> Redis.scard(client_key(client_id))
    |> String.to_integer
  end

  defp number_of_active_clients_for(redis, channel_name) when is_pid(redis) do
    redis
    |> Redis.scard(channel_key(channel_name))
    |> String.to_integer
  end

  defp active_clients_key do
    cluster_key("clients_with_active_subscriptions")
  end

  defp active_channels_key do
    cluster_key("channels_with_active_subscriptions")
  end

  defp client_key(client_id) do
    cluster_key("subscriptions_by_client:#{client_id}")
  end

  defp channel_key(channel_name) do
    cluster_key("subscriptions_by_channel:#{channel_name}")
  end

  defp client_member?(redis, client_id, channel_name) do
    case Redis.sismember(redis, client_key(client_id), channel_name) do
      "0" -> false
      "1" -> true
    end
  end

  defp channel_member?(redis, channel_name, client_id) do
    case Redis.sismember(redis, channel_key(channel_name), client_id) do
      "0" -> false
      "1" -> true
    end
  end
end