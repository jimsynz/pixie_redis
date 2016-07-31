defmodule Pixie.Redis do
  use Application
  alias Pixie.Redis.ConnectionPool

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children
    |> Supervisor.start_link(opts)
  end

  defdelegate with(callback), to: ConnectionPool

  defp children do
    import Supervisor.Spec, warn: false

    [
      supervisor(ConnectionPool, [])
    ]
  end

  defp opts do
    [strategy: :one_for_one, name: Pixie.Redis]
  end
end
