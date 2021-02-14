require "./spec_helper"

describe Caridina::Events::Redaction do
  it "deserializes doc example" do
    event = Caridina::Events::Event.from_json(%(
      {
        "content": {
            "reason": "Spamming"
        },
        "event_id": "$143273582443PhrSn:example.org",
        "origin_server_ts": 1432735824653,
        "redacts": "$fukweghifu23:localhost",
        "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
        "sender": "@example:example.org",
        "type": "m.room.redaction",
        "unsigned": {
            "age": 1234
        }
      }
    ))

    event = event.as(Caridina::Events::Redaction)
    event.content.reason.should eq("Spamming")
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.type.should eq("m.room.redaction")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end
