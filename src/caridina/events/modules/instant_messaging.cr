module Caridina::Events
  # Represents a m.room.message event.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-message)
  @[Type("m.room.message")]
  class Message < Caridina::Events::RoomEvent
    # Represents a m.room.message event's content.
    #
    # This event's content can have different fields according to its field
    # `msgtype`.
    # Each available content is represent by its own type.
    # To know which message event you are dealing with, you can use a case clause
    # over the content's type.
    #
    # ```
    # case event.content
    # when Caridina::Events::Message::Text
    #   # handle a message
    # when Caridina::Events::Message::MSC2676::Text
    #   # handle a message edit
    # when Caridina::Events::Message::Unknown
    #   # Unknown message type, but you can still inspect `event.content.body` and
    #   # `event.content.msgtype`.
    # else
    #   # fallback
    # end
    # ```
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#m-room-message)
    abstract class Content < Event::Content
      caridina_use_json_discriminator(
        {
          "msgtype" => {
            "m.text" => Text,
          },
          ["m.relates_to", "rel_type"] => {
            "m.replace" => MSC2676::Dispatcher,
          },
        },
        Unknown
      )

      getter body : String
      getter msgtype : String
      getter
    end

    # Represents a m.room.message event's content of type m.text.
    class Text < Content
      getter format : String?
      getter formatted_body : String?

      def initialize(@body, @formatted_body)
        @msgtype = "m.text"
        if !@formatted_body.nil?
          @format = "org.matrix.custom.html"
        end
      end
    end

    # Represents an unknown event.
    class Unknown < Content
    end

    # Implements MSC2676 (message editing).
    #
    # [Matrix MSC](https://github.com/matrix-org/matrix-doc/pull/2676)
    module MSC2676
      # :nodoc:
      class Dispatcher
        include JSON::Serializable

        caridina_use_json_discriminator(
          {
            "msgtype" => {
              "m.text" => Text,
            },
          }
        )
      end

      module Content
        @[JSON::Field(key: "m.new_content")]
        # Returns the content that will replace the previous message's content.
        #
        # Like a message's content, this new content can vary and you should use
        # a case clause to know what it is.
        getter new_content : Events::Message::Content
      end

      # Represents an edit message text content.
      class Text < Message::Text
        include Content

        def initialize(@body, @formatted_body, event_id)
          @relates_to = Event::RelatesTo.new("m.replace", event_id)
          @new_content = Message::Text.new(body, formatted_body)

          super(@body, @formatted_body)
        end
      end
    end
  end
end
