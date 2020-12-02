require "./responses/sync"

# This object allow you to register listeners to be executed when some events
# are received.
#
# This avoid you to have to parse the whole `Responses::Sync`.
# However `#process_response` must be called with a `Responses::Sync` manually.
# This allow you to control precisely when you want to handle events.
#
# ```
# syncer = Caridina::Syncer.new
# syncer.on(Caridina::Events::Message) do |event|
#   # TODO: actually do something
# end
#
# syncer.process_response(sync)
# ```
#
# Events sent to listeners are `Events::Event` objects.
# You should use a type restriction in order to access all their fields.
class Caridina::Syncer
  alias EventListener = Proc(Events::Event, Source, Nil)

  @[Flags]
  enum Source
    InvitedRooms
    JoinedRooms
  end

  @listeners = Hash(Events::Event.class, Array(Tuple(EventListener, Source))).new

  def process_response(sync : Responses::Sync) : Nil
    if rooms = sync.rooms
      rooms.join.each do |room_id, room|
        room.timeline.events.each do |event|
          if event = event.as?(Events::RoomEvent)
            event.room_id = room_id
            dispatch(event, Source::JoinedRooms)
          end
        end
      end

      rooms.invite.each do |room_id, room|
        room.invite_state.events.each do |event|
          event.room_id = room_id
          dispatch(event, Source::InvitedRooms)
        end
      end
    end
  end

  def on(event_type : Events::Event.class, source = Source::All, &listener : EventListener) : Nil
    on(event_type, source, listener)
  end

  def on(event_type : Events::Event.class, source = Source::All, listener : EventListener? = nil) : Nil
    if !listener.nil?
      if !@listeners.has_key?(event_type)
        @listeners[event_type] = Array(Tuple(EventListener, Source)).new
      end

      @listeners[event_type] << {listener, source}
    end
  end

  private def dispatch(event, event_source) : Nil
    @listeners[event.class]?.try &.each do |listener, source|
      if source.includes?(event_source)
        listener.call(event, event_source)
      end
    end
  end
end
