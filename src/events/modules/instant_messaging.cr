require "../macros"
require "../room_events"

module Caridina::Events
  # m.room.message
  struct Message < Caridina::Events::RoomEvent
    abstract struct Content < Event::Content
      use_json_discriminator_default(
        "msgtype",
        {
          "m.text" => Text,
        },
        Unknown
      )

      getter body : String
      getter msgtype : String
    end

    # m.text
    struct Text < Content
      getter format : String?
      getter formatted_body : String?

      def initialize(@body, @formatted_body)
        @msgtype = "m.text"
        if !@formatted_body.nil?
          @format = "org.matrix.custom.html"
        end
      end
    end

    struct Unknown < Content
    end
  end
end
