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
    end

    struct Unknown < Content
    end
  end
end
