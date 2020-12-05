require "http/client"
require "json"

require "./events"
require "./errors"
require "./modules/*"
require "./responses/*"

module Caridina
  # Interface to represent a Matrix client.
  module Connection
    class ExecError < Exception
    end

    abstract def edit_message(room_id : String, event_id : String, message : String, html : String? = nil) : Nil
    abstract def send_message(room_id : String, message : String, html : String? = nil) : String
    abstract def get(route, **options)
    abstract def post(route, data = nil, **options)
    abstract def put(route, data = nil)
  end

  class ConnectionImpl
    include Connection
    include Modules::Receipts
    include Modules::Typing

    Log = Caridina::Log.for(self)

    @syncing = false
    @tx_id = 0
    getter user_id : String = ""

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

      if !response.success
        raise Exception.new("Error with status_code #{response.status_code}")
      end

      data = Hash(String, String).from_json(response.body)
      data["access_token"]
    end

    def initialize(@hs_url : String, @access_token : String)
      @hs_url = @hs_url.gsub(%r{https?://}, "")

      Log.info { "Connecting to #{hs_url}" }
      @client_sync = HTTP::Client.new(@hs_url, 443, true)
      @user_id = whoami

      Log.info { "User's id is #{@user_id}" }
    end

    def create_filter(filter) : String
      response = post("/user/#{@user_id}/filter", filter)
      response = Responses::Filter.from_json(response)
      response.filter_id
    end

    def join(room_id) : Nil
      post("/rooms/#{room_id}/join")
    end

    def edit_message(room_id : String, event_id : String, message : String, html : String? = nil) : Nil
      tx_id = get_tx_id
      data = Events::Message::MSC2676::Text.new(message, html, event_id)
      put("/rooms/#{room_id}/send/m.room.message/#{tx_id}", data)
    end

    def send_message(room_id : String, message : String, html : String? = nil) : String
      tx_id = get_tx_id
      payload = Events::Message::Text.new(message, html)
      data = put("/rooms/#{room_id}/send/m.room.message/#{tx_id}", payload)

      Responses::Send.from_json(data).event_id
    end

    def sync(channel)
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

    def whoami : String
      response = get("/account/whoami")
      response = Responses::WhoAmI.from_json(response)
      response.user_id
    end

    def get(route, **options)
      exec "GET", route, **options
    end

    def post(route, data = nil, **options)
      exec "POST", route, **options, body: data
    end

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
      if !body.nil?
        body = body.to_json
        headers["Content-Type"] = "application/json"
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
