defmodule Pixie.Redis.Connection do

  def start_link([redis_url]) do
    config = Exredis.Config.parse(redis_url)
    Exredis.start_link(config.host, config.port, config.db, config.password, 0)
  end

end