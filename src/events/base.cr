require "./macros"

module Caridina::Events
  # Use this annotation to specify the event's type.
  annotation Type
  end

  # Base type representing an event.
  #
  # It has a class method `#from_json` that can be used to deserialize an event.
  #  You can then match the returned event type against known types.
  #
  # If the event is unknown, it returns nil.
  abstract struct Event
    include JSON::Serializable

    caridina_use_json_discriminator(
      {
        "type" => {
          "m.room.canonical_alias" => CanonicalAlias,
          "m.room.create"          => Create,
          "m.room.join_rules"      => JoinRules,
          "m.room.member"          => Member,
          "m.room.power_levels"    => PowerLevels,
          "m.room.redaction"       => Redaction,
          "m.room.message"         => Message,
        },
      },
      Unknown,
    )

    abstract struct Content
      include JSON::Serializable
    end

    getter type : String

    macro inherited
      {% if !@type.abstract? && !@type.instance_vars.find { |v| v.name == "content" } %}
        getter content : Content
      {% end %}
    end
  end

  struct Unknown < Event
    struct Content < Event::Content
    end

    getter content : Content?
  end
end
