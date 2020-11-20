require "./room_events"

module Caridina::Events
  abstract struct StateEvent < RoomEvent
    getter state_key : String
  end

  @[Type("m.room.canonical_alias")]
  struct CanonicalAlias < StateEvent
    struct Content < Event::Content
      getter alias : String?
      getter alt_aliases : Array(String)
    end
  end

  @[Type("m.room.create")]
  struct Create < StateEvent
    struct PreviousRoom
      include JSON::Serializable

      getter room_id : String
      getter event_id : String
    end

    struct Content < Event::Content
      getter creator : String
      @[JSON::Field(key: "m.federate")]
      getter m_federate = true
      getter room_version = "1"
      getter predecessor : PreviousRoom?
    end
  end

  @[Type("m.room.join_rules")]
  struct JoinRules < StateEvent
    enum JoinRule
      Public
      Knock
      Invite
      Private
    end

    struct Content < Event::Content
      getter join_rule : JoinRule
    end
  end

  @[Type("m.room.member")]
  struct Member < StateEvent
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

    struct StrippedState
      include JSON::Serializable
      include JSON::Serializable::Unmapped

      getter state_key : String
      getter type : String
      getter sender : String

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

    struct Content < Event::Content
      getter avatar_url : String?
      getter displayname : String?
      getter membership : Membership
      getter is_direct : Bool?
      getter third_party_invite : Invite?
    end

    getter unsigned : UnsignedData?
  end

  @[Type("m.room.power_levels")]
  struct PowerLevels < StateEvent
    struct Notifications
      include JSON::Serializable

      getter room = 50_u8
    end

    struct Content < Event::Content
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
end
