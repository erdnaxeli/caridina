require "./base"

module Caridina::Responses
  struct WhoAmI < Response
    getter user_id : String
  end
end
