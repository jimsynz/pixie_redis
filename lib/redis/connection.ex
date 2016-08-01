defmodule Pixie.Redis.Connection do

  @moduledoc """
  Set up a Redis connection with Exredis using the configured Redis URL.
  """

  def start_link([redis_url]) do
    config = Exredis.Config.parse(redis_url)
    Exredis.start_link(config.host, config.port, config.db, config.password, 0)
  end

end