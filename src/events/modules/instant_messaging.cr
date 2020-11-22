module Caridina::Events
  @[Type("m.room.message")]
  class Message < Caridina::Events::RoomEvent
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

    # m.text
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

    class Unknown < Content
    end

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
        getter new_content : Events::Message::Content
      end

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
