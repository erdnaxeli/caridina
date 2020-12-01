module Caridina::Events
  abstract class StateEvent < RoomEvent
    getter state_key : String
  end

  @[Type("m.room.canonical_alias")]
  class CanonicalAlias < StateEvent
    class Content < Event::Content
      getter alias : String?
      getter alt_aliases : Array(String)
    end
  end

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

  # This event represents a StrippedState event.
  #
  # It is used in `Member` event and in `Responses::Sync` in invited rooms's state.
  # It is actually a state event, but it does not inherit from `StateEvent` as
  # some fields are not presents.
  #
  # This type is used to represents many distinct stripped state events.
  # To distinguish them you must check the `#content`'s type.
  class StrippedState < Event
    include JSON::Serializable::Unmapped

    getter state_key : String
    getter sender : String

    # "room_id" is not set in events returned from the sync API, so we need to
    # set it up ourself.
    property room_id : String?

    def content #: Event::Content
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
