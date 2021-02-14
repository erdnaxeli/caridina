module Caridina::Events
  # Represents a room event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#room-events)
  abstract class RoomEvent < Event
  end

  make_room_event(Redaction, "m.room.redaction", reason : String?)
end
