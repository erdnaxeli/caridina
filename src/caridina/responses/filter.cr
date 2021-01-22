require "./base"

module Caridina::Responses
  struct Filter < Response
    getter filter_id : String
  end
end
