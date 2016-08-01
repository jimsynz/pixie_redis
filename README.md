# Pixie.Redis

Redis storage backend for [Pixie](https://github.com/messagerocket/pixie).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `pixie_redis` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:pixie_redis, "~> 0.1.0"}]
    end
    ```

  2. Ensure `pixie_redis` is started before your application:

    ```elixir
    def application do
      [applications: [:pixie_redis]]
    end
    ```

## Configuration

Pixie's Redis connection is configured using the following values in your project's `config.exs`:

```elixir
config :pixie_redis,
  redis_url: redis://localhost:6379/0,
  pool_size: 10,
  pool_max_overflow: 1
```
