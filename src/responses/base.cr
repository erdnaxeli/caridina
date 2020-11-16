module Caridina::Responses
  abstract struct Response
    include JSON::Serializable
  end
end
