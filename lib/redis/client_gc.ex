defmodule Pixie.Redis.ClientGC do
  use GenServer
  use Pixie.Redis.ConnectionPool
  alias Pixie.Redis.Client

  @moduledoc """
  This server removes stale clients from Redis after they've expired.
  """

  @default_gc_frequency 5_000 # 5 seconds

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    {:ok, nil, gc_frequency}
  end

  def handle_info(:timeout, state) do
    remove_expired_clients
    {:noreply, state, gc_frequency}
  end

  defp gc_frequency do
    Application.get_env(:pixie_redis, :gc_frequency, @default_gc_frequency)
  end

  defp cutoff do
    trunc(now - (Pixie.Redis.timeout * 2.5 * 1000))
  end

  defp now do
    DateTime.utc_now
    |> DateTime.to_unix(:microseconds)
  end

  defp remove_expired_clients do
    with_connection(fn (redis) ->
      redis
      |> Redis.zrangebyscore(alive_key, "-inf", cutoff)
      |> Enum.each(fn (client_id) ->
        Client.destroy(redis, client_id)
      end)
    end)
  end

  defp alive_key do
    cluster_key("alive_clients")
  end

end