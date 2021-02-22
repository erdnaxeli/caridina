module Caridina::Events
  # Use this annotation to specify the event's type.
  annotation Type
  end

  # Base type representing an event.
  #
  # All types returned by the `Caridina::Connection::Sync` method will be
  # of this type.
  # You can then match the returned event type against known types to be able
  # to use all the event's field.
  #
  # If the event is unknown, it returns nil.
  abstract class Event
    include JSON::Serializable

    caridina_use_json_discriminator(
      {
        "type" => {
          "m.room.canonical_alias" => [CanonicalAlias, RedactedCanonicalAlias],
          "m.room.create"          => [Create, RedactedCreate],
          "m.room.join_rules"      => [JoinRules, RedactedJoinRules],
          "m.room.member"          => [Member, RedactedMember],
          "m.room.power_levels"    => [PowerLevels, RedactedPowerLevels],
          "m.room.redaction"       => [Redaction, RedactedRedaction],
          "m.room.message"         => [Message, RedactedMessage],
        },
      },
      Unknown,
    )
  end

  # Represents an unknown event.
  #
  # The content will alway be nil.
  class Unknown < Event
    getter type : String
  end
end
