require "json"

require "./base"

module Caridina::Events
  abstract struct RoomEvent < Event
    abstract struct UnsignedData
      include JSON::Serializable

      getter age : Int64
      getter transaction_id : String?
    end

    getter event_id : String
    getter sender : String
    getter origin_server_ts : UInt64
    getter room_id : String?

    macro inherited
      {% if !@type.abstract? && !@type.instance_vars.find { |v| v.name == "unsigned" } %}
        struct UnsignedData < RoomEvent::UnsignedData
        end

        getter unsigned : UnsignedData?
      {% end %}
    end
  end

  @[Type("m.room.redaction")]
  struct Redaction < RoomEvent
    struct Content < Event::Content
      getter reason : String?
    end
  end
end
