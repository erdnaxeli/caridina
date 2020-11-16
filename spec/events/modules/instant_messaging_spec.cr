require "../../../src/events/modules/instant_messaging"

describe Caridina::Events::Message do
  it "deserializes unknown message" do
    event = Caridina::Events::Message.from_json(%(
{
  "content": {
      "body": "This is a body",
      "unknown": "unknown",
      "msgtype": "m.unknown"
  },
  "event_id": "$143273582443PhrSn:example.org",
  "origin_server_ts": 1432735824653,
  "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
  "sender": "@example:example.org",
  "type": "m.room.message",
  "unsigned": {
      "age": 1234
  }
}
    ))

    content = event.content.as(Caridina::Events::Message::Unknown)
    content.body.should eq("This is a body")
    content.msgtype.should eq("m.unknown")
  end

  it "deserializes doc example" do
    event = Caridina::Events::Message.from_json(%(
{
    "content": {
        "body": "This is an example text message",
        "format": "org.matrix.custom.html",
        "formatted_body": "<b>This is an example text message</b>",
        "msgtype": "m.text"
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "type": "m.room.message",
    "unsigned": {
        "age": 1234
    }
}
    ))

    content = event.content.as(Caridina::Events::Message::Text)
    content.body.should eq("This is an example text message")
    content.format.should eq("org.matrix.custom.html")
    content.formatted_body.should eq("<b>This is an example text message</b>")
    content.msgtype.should eq("m.text")
    event.origin_server_ts.should eq(1432735824653)
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.type.should eq("m.room.message")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end
