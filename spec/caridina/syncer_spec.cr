require "../../src/caridina/syncer"

require "./spec_helper"

def listener(event)
  puts event
end

describe Caridina::Syncer do
  it "accepts blocks" do
    syncer = Caridina::Syncer.new
    syncer.on(Caridina::Events::Message) do |event|
      puts event
    end
  end

  it "accepts proc" do
    syncer = Caridina::Syncer.new
    syncer.on(Caridina::Events::Message, ->listener(Caridina::Events::Event))
  end

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
      Caridina::Events::StrippedMember,
      Caridina::Syncer::Source::InvitedRooms
    ) do |event, source|
      events << event
      sources << source
      calls += 1
    end
    sync = Caridina::Responses::Sync.from_json(SYNC)
    syncer.process_response(sync)

    calls.should eq(1)

    event = events[0].as(Caridina::Events::StrippedMember)
    event.content.membership.should eq(Caridina::Events::Member::Membership::Invite)

    sources.should eq([Caridina::Syncer::Source::InvitedRooms])
  end
end
