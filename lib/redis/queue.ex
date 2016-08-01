defmodule Pixie.Redis.Queue do
  use Pixie.Redis.ConnectionPool

  @key_ttl 3600

  @moduledoc """
  Store client message queues in Redis.
  """

  def queue(client_id, messages) do
    with_connection(fn (redis) ->
      Redis.multi(redis)

      messages
      |> Enum.each(fn (message) ->
        message =
          message
          |> :erlang.term_to_binary

        Redis.lpush(redis, key(client_id), message)
      end)

      Redis.expire(redis, key(client_id), @key_ttl)
      Redis.exec(redis)
    end)
  end

  def dequeue(client_id) do
    with_connection(fn (redis) ->
      do_dequeue(redis, client_id, [])
    end)
  end

  defp do_dequeue(redis, client_id, result) do
    case Redis.rpop(redis, key(client_id)) do
      :undefined ->
        result
      message ->
        message = :erlang.binary_to_term(message)
        [ message | do_dequeue(redis, client_id, result) ]
    end
  end

  defp key(client_id) do
    cluster_key("message_queue:#{client_id}")
  end
end