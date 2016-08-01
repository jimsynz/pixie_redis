defmodule Pixie.Redis do
  use Application
  alias Pixie.Redis.ConnectionPool

  @default_timeout 25_000 # 25 seconds.

  @moduledoc """
  A Pixie backend using Redis as the backend registry.
  """

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children
    |> Supervisor.start_link(opts)
  end

  def timeout do
    Application.get_env(:pixie_redis, :timeout, @default_timeout)
  end

  defp children do
    import Supervisor.Spec, warn: false

    [
      supervisor(ConnectionPool, []),
      worker(Pixie.Redis.ClientGC, [])
    ]
  end

  defp opts do
    [strategy: :one_for_one, name: Pixie.Redis]
  end
end
