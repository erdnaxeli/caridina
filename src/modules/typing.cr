module Caridina::Modules::Typing
  # Sends a typing notification
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#put-matrix-client-r0-rooms-roomid-typing-userid)
  def send_typing(room_id : String, timeout = 3000, typing = true) : Nil
    put(
      "/rooms/#{room_id}/typing/#{@user_id}",
      data: {
        typing:  typing,
        timeout: timeout,
      }
    )
  end

  # Keeps sending a typing notification while the block runs.
  #
  # The notification is sent every 30 seconds.
  # Once the block ends, it sends a last call to stop the notification typing.
  def typing(room_id : String, &block)
    channel = Channel(Nil).new

    spawn do
      timeout = 30000
      send_typing(room_id, timeout: timeout)

      loop do
        select
        when channel.receive?
          send_typing(room_id, typing: false)
          break
        when timeout timeout.milliseconds
          send_typing(room_id, timeout: timeout)
        end
      end
    end

    yield
    channel.close
  end
end
