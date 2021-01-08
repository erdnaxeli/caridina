module Caridina::Events
  # Represents a state event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#state-event-fields)
  abstract class StateEvent < RoomEvent
    getter state_key : String
  end

  # Represents a m.room.canonical_alias event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-canonical-alias)
  @[Type("m.room.canonical_alias")]
  class CanonicalAlias < StateEvent
    class Content < Event::Content
      getter alias : String?
      getter alt_aliases : Array(String)
    end
  end

  # Represents a m.room.create event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-create)
  @[Type("m.room.create")]
  class Create < StateEvent
    struct PreviousRoom
      include JSON::Serializable

      getter room_id : String
      getter event_id : String
    end

    class Content < Event::Content
      getter creator : String
      @[JSON::Field(key: "m.federate")]
      getter m_federate = true
      getter room_version = "1"
      getter predecessor : PreviousRoom?
    end
  end

  # Represents a m.room.join_rules event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-join-rules)
  @[Type("m.room.join_rules")]
  class JoinRules < StateEvent
    enum JoinRule
      Public
      Knock
      Invite
      Private
    end

    class Content < Event::Content
      getter join_rule : JoinRule
    end
  end

  # Represents a m.room.member event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-member)
  @[Type("m.room.member")]
  class Member < StateEvent
    enum Membership
      Invite
      Join
      Knock
      Leave
      Ban
    end

    struct Invite
      include JSON::Serializable

      getter display_name : String
    end

    struct UnsignedData < RoomEvent::UnsignedData
      include JSON::Serializable

      getter invite_room_state : Array(StrippedState)?
    end

    class Content < Event::Content
      getter avatar_url : String?
      getter displayname : String?
      getter membership : Membership
      getter is_direct : Bool?
      getter third_party_invite : Invite?
    end

    getter unsigned : UnsignedData?
  end

  # Represents a m.room.power_levels event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-power-levels)
  @[Type("m.room.power_levels")]
  class PowerLevels < StateEvent
    struct Notifications
      include JSON::Serializable

      getter room = 50_u8
    end

    class Content < Event::Content
      getter ban = 50_u8
      getter events = Hash(String, UInt8).new
      getter events_default = 0_u8
      getter invite = 50_u8
      getter kick = 50_u8
      getter redact = 50_u8
      getter states_default = 50_u8
      getter users = Hash(String, UInt8).new
      getter users_default = 0_i8
      getter notifications : Notifications?
    end
  end

  # Represents a StrippedState event.
  #
  # It is used in `Member` event and in `Responses::Sync` in invited rooms' state.
  # It is actually a state event, but it does not inherit from `StateEvent` as
  # some fields are not presents.
  #
  # This type is used to represents many distinct stripped state events.
  # To distinguish them you must check the `#content`'s type.
  class StrippedState < Event
    include JSON::Serializable::Unmapped

    getter state_key : String
    getter sender : String
    property room_id : String?

    def content : Event::Content
      json = @json_unmapped["content"].to_json

      {% begin %}
        case type
          {% for subclass in StateEvent.subclasses %}
            {% if subclass.annotation(Type) %}
              when {{ subclass.annotation(Type)[0] }}
                {{subclass.id}}::Content.from_json(json)
            {% end %}
          {% end %}
        else
          Unknown::Content.from_json(json)
        end
      {% end %}
    end
  end
end
