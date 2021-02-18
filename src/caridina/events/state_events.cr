module Caridina::Events
  # Represents a state event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#state-event-fields)
  abstract class StateEvent < RoomEvent
  end

  # Represents a StrippedState event.
  #
  # It is used in `Member` event and in `Responses::Sync` in invited rooms' state.
  # It contains a subset of state events' fields.
  #
  # This type is used to represents many distinct stripped state events. See
  # subtypes.
  abstract class StrippedState < Event
    caridina_use_json_discriminator(
      {
        "type" => {
            # {% for event in StrippedState.all_subclasses.select &.annotation(Type) %}
            #   {% if type = event.annotation(Type) %}
            #     {{ type[0] }} => {{event}},
            #   {% end %}
            # {% end %}
            "m.room.canonical_alias" => StrippedCanonicalAlias,
            "m.room.create" => StrippedCreate,
            "m.room.join_rules" => StrippedJoinRules,
            "m.room.member" => StrippedMember,
            "m.room.power_levels" => StrippedPowerLevels,
        }
      },
      StrippedUnknown,
    )
  end

  class StrippedUnknown < StrippedState
    getter sender : String
    getter state_key : String
    getter type : String

    property room_id : String?
  end

  # Represents a m.room.canonical_alias event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-canonical-alias)
  make_state_event(
    CanonicalAlias,
    "m.room.canonical_alias",
    alias : String?,
    alt_aliases : Array(String),
  )

  # Represents a m.room.create event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-create)
  make_state_event(
    Create,
    "m.room.create",
    creator : String,
    room_version = "1",
    predecessor : PreviousRoom?,
  ) do
    struct PreviousRoom
      include JSON::Serializable

      getter room_id : String
      getter event_id : String
    end

    class Content
      @[JSON::Field(key: "m.federate")]
      getter m_federate = true
    end
  end

  # Represents a m.room.join_rules event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-join-rules)
  make_state_event(
    JoinRules,
    "m.room.join_rules",
    join_rule : JoinRule
  ) do
    enum JoinRule
      Public
      Knock
      Invite
      Private
    end
  end

  # Represents a m.room.member event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-member)
  make_state_event(
    Member,
    "m.room.member",
    avatar_url : String?,
    displayname : String?,
    membership : Member::Membership,
    is_direct : Bool?,
    third_party_invite : Invite?,
  ) do
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

    struct UnsignedData
      getter invite_room_state : Array(StrippedState)?
    end
  end

  # Represents a m.room.power_levels event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-power-levels)
  make_state_event(
    PowerLevels,
    "m.room.power_levels",
    ban = 50_u8,
    events = Hash(String, UInt8).new,
    events_default = 0_u8,
    invite = 50_u8,
    kick = 50_u8,
    redact = 50_u8,
    states_default = 50_u8,
    users = Hash(String, UInt8).new,
    users_default = 0_i8,
    notifications : Notifications?,
  ) do
    struct Notifications
      include JSON::Serializable

      getter room = 50_u8
    end
  end
end
