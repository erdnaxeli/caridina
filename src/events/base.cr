module Caridina::Events
  # Use this annotation to specify the event's type.
  annotation Type
  end

  # Base type representing an event.
  #
  # All types returned by the `Caridina::ConnectionImpl::Sync` method will be
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

    # Represents a relation to another event.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#forming-relationships-between-events)
    struct RelatesTo
      include JSON::Serializable

      getter rel_type : String?
      getter event_id : String?

      def initialize(@rel_type, @event_id)
      end
    end

    abstract class Content
      include JSON::Serializable

      # This implements MSC2674 (event relationships).
      #
      # [Matrix MSC](https://github.com/matrix-org/matrix-doc/pull/2674)
      @[JSON::Field(key: "m.relates_to")]
      getter relates_to : RelatesTo?
    end

    getter type : String

    # Automatically defines a getter "content" if the subclass does not define one.
    macro inherited
      macro finished
        \{% if !@type.abstract? && !@type.has_method?("content") %}
          getter content : Content
        \{% end %}
      end
    end
  end

  # Represents an unknown event.
  #
  # The content will alway be nil.
  class Unknown < Event
    class Content < Event::Content
    end

    getter content : Content? = nil
  end
end
