module Caridina::Events
  abstract class RoomEvent < Event
    abstract struct UnsignedData
      include JSON::Serializable

      getter age : Int64
      getter transaction_id : String?
    end

    getter event_id : String
    getter sender : String
    getter origin_server_ts : UInt64
    # "room_id" is not set in events returned from the sync API, so we need to
    # set it up ourself.
    property room_id : String?

    macro inherited
      {% if !@type.abstract? && !@type.has_method?("unsigned") %}
        struct UnsignedData < RoomEvent::UnsignedData
        end

        getter unsigned : UnsignedData?
      {% end %}
    end
  end

  @[Type("m.room.redaction")]
  class Redaction < RoomEvent
    class Content < Event::Content
      getter reason : String?
    end
  end
end
