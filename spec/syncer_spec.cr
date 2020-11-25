require "../src/syncer"

require "./spec_helper"

describe Caridina::Syncer do
  it "sends event to listeners" do
    received_event = nil
    calls = 0

    syncer = Caridina::Syncer.new
    syncer.on(Caridina::Events::Message) do |event|
      received_event = event
      calls += 1
    end
    sync = Caridina::Responses::Sync.from_json(SYNC)
    syncer.process_response(sync)

    received_event.class.should eq(Caridina::Events::Message)
    calls.should eq(1)
  end
end
