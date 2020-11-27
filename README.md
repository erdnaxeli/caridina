# caridina

A [Matrix](https://matrix.org) client library.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     caridina:
       github: erdnaxeli/caridina
   ```

2. Run `shards install`

## Usage

### Connecting

Create a new connection object:

```crystal
require "caridina"

conn = Caridina::ConnectionImpl.new(
  "https://my-favorite-hs.example.org",
  "my access token",
)
```

You can also login to get a new access token:

```crystal
access_token = Caridina::ConnectionImpl.login(
  "https://my-favorite-hs.example.org",
  "@mybotuserid:my-favorite-hs.example.org",
  "my secret password",
)
```

### Sync

Now we can create a new channel, and tell the connection object to start syncing.
The sync responses will be streamed in the channel.

```
matrix = Channel(Caridina::Events::Sync).new
conn.sync(matrix)

sync = matrix.receive
```

You have now a [sync response](src/response/sync.cr).

If you don't want to go through the whole sync response by yourself (which is
understandable), we provide you a [Caridina::Syncer](src/syncer.cr) object.

```
syncer = Caridina::Syncer.new
syncer.on(Caridina::Events::Message) do |event|
  # TODO: actually do something
end

syncer.process_response(sync)
```

> :warning: The syncer is a new feature still in development.
> It currently only supports events in the joined rooms timeline.
> To access to other events, you need to go through the sync response.

### Read event

If you don't use the `Syncer`, most of the events you will see in the sync response
will be `Caridina::Events::Event` objects. You need to restrict the type of an event
object to access all its fields.

```
sync.rooms.try &.join.each do |room_id, room|
  room.timeline.events.each do |event|
    case event
    when Caridina::Events::Member
      # someone's membership changed
    when Caridina:: Events::PowerLevels
      # some authorization changed
    when Caridina::Events::Messages
      # someone talked
    else
      # unknown event
    end
  end
end
```

Sometimes the event's content can be polymorphic too.
That is especially the case for message events.
By using again a `case` clause you can restrict its type to access all its fields.

### Send events

Their is not a single method to send an event.
Instead this library provides a set of methods that correspond to different
actions you may want to do.
You usually do not need to worry about crafting the event to send.

> :warning: This part is in a very early stage.
> Currently only a few methods are provided.

```
# join a room
conn.join("!room_id:matrix.org")
# send a message
event_id = conn.send_message("!room_id:matrix.org", "Hello, wurld!")
# edit a message
conn.edit_message("!room_id:matrix.org", "Hello, world!"))
```

## Development

Install the depencies with `shards install`.

* `make test` runs the tests
* `make lint` runs the formater plus a linter

## Contributing

1. Fork it (<https://github.com/erdnaxeli/caridina/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [erdnaxeli](https://github.com/erdnaxeli) - creator and maintainer
