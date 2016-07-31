defmodule Pixie.Redis.ConnectionPool do
  use Supervisor
  alias Pixie.Redis.Connection

  @default_pool_size 10
  @default_pool_overflow 1

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children
    |> supervise(strategy: :one_for_one)
  end

  def with(callback) when is_function(callback, 1) do
    :poolboy.transaction(Connection, callback, :infinity)
  end

  defp poolboy_config do
    [
      name:          {:local, Connection},
      worker_module: Connection,
      size:          pool_size,
      max_overflow:  pool_max_overflow
    ]
  end

  defp children do
    [
      :poolboy.child_spec(__MODULE__, poolboy_config, [redis_url])
    ]
  end

  defp pool_size do
    :pixie_redis
    |> Application.get_env(:pool_size, @default_pool_size)
  end

  defp pool_max_overflow do
    :pixie_redis
    |> Application.get_env(:pool_max_overflow, @default_pool_overflow)
  end

  defp redis_url do
    :pixie_redis
    |> Application.get_env(:redis_url)
  end
end