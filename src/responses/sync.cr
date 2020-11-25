require "json"

require "./base"

module Caridina::Responses
  struct Sync < Response
    struct Rooms
      include JSON::Serializable

      getter join : Hash(String, JoinedRoom)
      getter invite : Hash(String, InvitedRoom)
    end

    struct JoinedRoom
      include JSON::Serializable

      getter timeline : Timeline
    end

    struct Timeline
      include JSON::Serializable

      getter events : Array(Events::Event)
    end

    struct InvitedRoom
      include JSON::Serializable

      getter invite_state : InviteState
    end

    struct InviteState
      include JSON::Serializable

      getter events : Array(Events::Member::StrippedState)
    end

    getter next_batch : String
    getter rooms : Rooms?
  end
end
