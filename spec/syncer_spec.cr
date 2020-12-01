require "../src/syncer"

require "./spec_helper"

describe Caridina::Syncer do
  it "sends events to listeners without source" do
    received_event = nil
    calls = 0

    syncer = Caridina::Syncer.new
    syncer.on(Caridina::Events::Message) do |event|
      received_event = event
      calls += 1
    end
    sync = Caridina::Responses::Sync.from_json(SYNC)
    syncer.process_response(sync)

    event = received_event.as(Caridina::Events::Message)
    event.content.body.should eq("This is an example text message")

    calls.should eq(1)
  end

  it "sends events to listeners with JoinedRooms source" do
    events = Array(Caridina::Events::Event).new
    sources = Array(Caridina::Syncer::Source).new
    calls = 0

    syncer = Caridina::Syncer.new
    syncer.on(
      Caridina::Events::Member,
      Caridina::Syncer::Source::JoinedRooms
    ) do |event, source|
      events << event
      sources << source
      calls += 1
    end
    sync = Caridina::Responses::Sync.from_json(SYNC)
    syncer.process_response(sync)

    calls.should eq(1)

    event = events[0].as(Caridina::Events::Member)
    event.content.displayname.should eq("Alice Margatroid Timeline")

    sources.should eq([Caridina::Syncer::Source::JoinedRooms])
  end

  it "sends event to listeners with InvitedRooms source" do
    events = Array(Caridina::Events::Event).new
    sources = Array(Caridina::Syncer::Source).new
    calls = 0

    syncer = Caridina::Syncer.new
    syncer.on(
      Caridina::Events::StrippedState,
      Caridina::Syncer::Source::InvitedRooms
    ) do |event, source|
      events << event
      sources << source
      calls += 1
    end
    sync = Caridina::Responses::Sync.from_json(SYNC)
    syncer.process_response(sync)

    calls.should eq(2)

    event = events[0].as(Caridina::Events::StrippedState)
    event.type.should eq("m.room.name")
    event.content.class.should eq(Caridina::Events::Unknown::Content)

    event = events[1].as(Caridina::Events::StrippedState)
    content = event.content.as(Caridina::Events::Member::Content)
    content.membership.should eq(Caridina::Events::Member::Membership::Invite)

    sources.should eq(
      [Caridina::Syncer::Source::InvitedRooms, Caridina::Syncer::Source::InvitedRooms]
    )
  end
end
