defmodule Pixie.Redis.ConnectionPool do
  use Supervisor
  alias Pixie.Redis.Connection
  require Logger

  @default_pool_size 10
  @default_pool_overflow 1
  @default_redis_url "redis://localhost:6379"

  @moduledoc """
  A Supervisor handling a Redis connection pool with Poolboy.
  """

  defmacro __using__(_opts) do
    quote do
      import Pixie.Redis.ConnectionPool, only: [with_connection: 1, cluster_key: 1, local_key: 1]
      alias Exredis.Api, as: Redis
    end
  end

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    children
    |> supervise(strategy: :one_for_one)
  end

  def with_connection(callback) when is_function(callback, 1) do
    :poolboy.transaction(Connection, callback, 5000)
  end

  def cluster_key(key) do
    "pixie:#{Mix.env}:#{key}"
  end

  def local_key(key) do
    {:ok, hostname} = :inet.gethostname
    cluster_key("#{hostname}:#{key}")
  end

  def reset! do
    with_connection(fn (redis) ->
      Exredis.Api.flushdb(redis)
    end)
    :ok
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
    |> Application.get_env(:redis_url, @default_redis_url)
  end
end