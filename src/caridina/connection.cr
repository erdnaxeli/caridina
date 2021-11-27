require "http/client"
require "json"

require "./events"
require "./errors"
require "./modules/*"
require "./responses/*"

module Caridina
  # Interface that represents a Matrix connection.
  module ConnectionInterface
    class ExecError < Exception
    end

    abstract def edit_message(room_id : String, event_id : String, message : String, html : String? = nil) : Nil
    abstract def send_message(room_id : String, message : String, html : String? = nil) : String
    # :nodoc:
    abstract def get(route, **options)
    # :nodoc:
    abstract def post(route, data = nil, **options)
    # :nodoc:
    abstract def put(route, data = nil)
  end

  # A Matrix connection.
  #
  # This is the main entrypoint for this library.
  # You will find here all methods to interact with the Matrix API.
  #
  # Those methods handle retrying when the connection is
  # being rate limited.
  # If there is another error, an `ExecError` while be returned.
  class Connection
    include ConnectionInterface
    include Modules::Receipts
    include Modules::Typing

    Log = Caridina::Log.for(self)

    @syncing = false
    @tx_id = 0

    # Returns the connected account's user_id.
    getter user_id : String = ""

    # Logs in using to a given homeserver and returns the access token.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#post-matrix-client-r0-login)
    def self.login(hs_url : String, user_id : String, password : String) : String
      data = {
        type:       "m.login.password",
        identifier: {
          type: "m.id.user",
          user: user_id,
        },
        password: password,
      }
      response = HTTP::Client.post(
        "#{hs_url}/_matrix/client/r0/login",
        headers: HTTP::Headers{"Content-Type" => "application/json"},
        body: data.to_json,
      )

      if !response.success?
        raise Exception.new("Error with status_code #{response.status_code}")
      end

      data = Hash(String, String).from_json(response.body)
      data["access_token"]
    end

    # Create a new connection object using an access_token.
    def initialize(@hs_url : String, @access_token : String)
      @hs_url = @hs_url.gsub(%r{https?://}, "")

      Log.info { "Connecting to #{hs_url}" }
      @client_sync = HTTP::Client.new(@hs_url, 443, true)
      @user_id = whoami

      Log.info { "User's id is #{@user_id}" }
    end

    # Creates a sync filter and returns its id.
    #
    # The *filter* parameter must be a JSON serializable object.
    #
    # TODO: This should be implement with a proper model object.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#post-matrix-client-r0-user-userid-filter)
    def create_filter(filter) : String
      response = post("/user/#{@user_id}/filter", filter)
      response = Responses::Filter.from_json(response)
      response.filter_id
    end

    # Joins a room.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#post-matrix-client-r0-rooms-roomid-join)
    def join(room_id) : Nil
      post("/rooms/#{room_id}/join")
    end

    # Edits a message.
    #
    # Only `m.text` messages are supported for now.
    def edit_message(room_id : String, event_id : String, message : String, html : String? = nil) : Nil
      tx_id = get_tx_id
      data = Events::Message::MSC2676::Text.new(message, html, event_id)
      put("/rooms/#{room_id}/send/m.room.message/#{tx_id}", data)
    end

    # Sends a message to a given room.
    #
    # Only `m.text` messages are supported for now.
    def send_message(room_id : String, message : String, html : String? = nil) : String
      tx_id = get_tx_id
      payload = Events::Message::Text.new(message, html)
      data = put("/rooms/#{room_id}/send/m.room.message/#{tx_id}", payload)

      Responses::Send.from_json(data).event_id
    end

    # Starts syncing.
    #
    # This method starts a new fiber wich will run sync queries, and send received
    # events in *channel*.
    #
    # It uses a filter to limit the received events to supported ones.
    #
    # When called, it will first do an inital sync.
    # This first sync may return events you already seen in a previous sync.
    # You should handle this in your code, either by skipping the first sync or
    # by storing the id of the events you processed.
    #
    # TODO: accept an *next_batch* parameter to skip the initial sync.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#get-matrix-client-r0-sync)
    def sync(channel : Channel(Responses::Sync))
      if @syncing
        raise Exception.new("Already syncing")
      end

      # create filter to use for sync
      filter = {
        account_data: {types: [] of String},
        presence:     {types: [] of String},
        room:         {
          account_data: {types: [] of String},
          ephemeral:    {types: [] of String},
          timeline:     {lazy_load_members: true},
          state:        {lazy_load_members: true},
        },
      }
      filter_id = create_filter filter

      spawn do
        next_batch = nil

        loop do
          begin
            if next_batch.nil?
              response = get("/sync", is_sync: true, filter: filter_id)
            else
              response = get("/sync", is_sync: true, filter: filter_id, since: next_batch, timeout: 300_000)
            end
          rescue ex : ExecError
            # The sync failed, this is probably due to the HS having
            # difficulties, let's not harm it anymore.
            Log.error(exception: ex) { "Error while syncing, waiting 10s before retry" }
            sleep 10
            next
          end

          sync = Responses::Sync.from_json(response)
          next_batch = sync.next_batch
          channel.send(sync)
        end
      end
    end

    # Returns the connected account's user_id.
    #
    # You probably should use `user_id` which already store that information.
    #
    # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#get-matrix-client-r0-account-whoami)
    def whoami : String
      response = get("/account/whoami")
      response = Responses::WhoAmI.from_json(response)
      response.user_id
    end

    # :nodoc:
    def get(route, **options)
      exec "GET", route, **options
    end

    # :nodoc:
    def post(route, data = nil, **options)
      exec "POST", route, **options, body: data
    end

    # :nodoc:
    def put(route, data = nil)
      exec "PUT", route, body: data
    end

    private def exec(method, route, is_sync = false, is_admin = false, body = nil, **options)
      params = {} of String => String
      if !options.nil?
        options.each do |k, v|
          params[k.to_s] = v.to_s
        end
      end

      params = HTTP::Params.encode(params)
      if is_admin
        url = "/_synapse/admin#{route}?#{params}"
      else
        url = "/_matrix/client/r0#{route}?#{params}"
      end

      if is_sync
        client = @client_sync
      else
        client = HTTP::Client.new @hs_url, 443, true
      end

      headers = HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
      headers["Content-Type"] = "application/json"
      if body.nil?
        # Synapse wants a valid JSON value, even if empty
        body = "{}"
      else
        body = body.to_json
      end

      Log.debug { "#{method} #{url}" }
      loop do
        response = client.exec method, url, headers, body

        begin
          case response.status_code
          when 200
            return response.body
          when 429
            content = JSON.parse(response.body)
            error = Errors::RateLimited.new(content)
            Log.warn { "Rate limited, retry after #{error.retry_after_ms}" }
            sleep (error.retry_after_ms + 100).milliseconds
          else
            raise ExecError.new("Invalid status code #{response.status_code}: #{response.body}")
          end
        rescue ex : JSON::ParseException
          Log.error(exception: ex) { "Error while parsing JSON" }
          Log.error { "Response body: #{response.body}" }
          raise ExecError.new
        end
      end
    end

    private def get_tx_id : String
      @tx_id += 1
      "#{Time.utc.to_unix_f}.#{@tx_id}"
    end
  end
end
