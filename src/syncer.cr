require "./responses/sync"

class Caridina::Syncer
  alias EventListener = Proc(Events::Event, Nil)
  @listeners = Hash(Events::Event.class, Array(EventListener)).new

  def process_response(sync : Responses::Sync) : Nil
    sync.rooms.try &.join.each do |room_id, room|
      room.timeline.events.each do |event|
        if event = event.as?(Events::RoomEvent)
          event.room_id = room_id

          @listeners[event.class]?.try &.each do |listener|
            listener.call(event)
          end
        end
      end
    end
  end

  def on(event_type : Events::Event.class, &block : EventListener) : Nil
    if !@listeners.has_key?(event_type)
      @listeners[event_type] = Array(EventListener).new
    end

    @listeners[event_type] << block
  end
end
