require "./base"

module Caridina::Responses
  struct Send < Response
    getter event_id : String
  end
end
