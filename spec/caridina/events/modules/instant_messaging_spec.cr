require "./spec_helper"

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

  it "deserializes text edit" do
    r = Caridina::Events::Event.from_json(%(
{
  "content": {
    "body": "s/foo/bar/",
    "msgtype": "m.text",
    "m.new_content": {
      "body": "Hello! My name is bar",
      "msgtype": "m.text"
    },
    "m.relates_to": {
      "rel_type": "m.replace",
      "event_id": "$some_event_id"
    }
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

    r = r.as(Caridina::Events::Message)
    content = r.content.as(Caridina::Events::Message::Text)
    content.body.should eq("s/foo/bar/")
    content.msgtype.should eq("m.text")
    content.relates_to.should_not be_nil
    content.relates_to.try &.rel_type.should eq("m.replace")
    content.relates_to.try &.event_id.should eq("$some_event_id")

    content = r.content.as(Caridina::Events::Message::MSC2676::Text)
    new_content = content.new_content.as(Caridina::Events::Message::Text)
    new_content.body.should eq("Hello! My name is bar")
    new_content.msgtype.should eq("m.text")
  end

  it "deserializes unknown edit to their msgtype" do
    r = Caridina::Events::Event.from_json(%(
{
  "content": {
    "body": "s/foo/bar/",
    "msgtype": "m.text",
    "m.new_content": {
      "body": "Hello! My name is bar",
      "msgtype": "m.text"
    },
    "m.relates_to": {
      "rel_type": "m.unknown",
      "event_id": "$some_event_id"
    }
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

    r = r.as(Caridina::Events::Message)
    content = r.content.as(Caridina::Events::Message::Text)
    content.body.should eq("s/foo/bar/")
    content.msgtype.should eq("m.text")
    content.relates_to.should_not be_nil
    content.relates_to.try &.rel_type.should eq("m.unknown")
    content.relates_to.try &.event_id.should eq("$some_event_id")
  end

  it "deserializes a redacted message" do
    event = Caridina::Events::Event.from_json(%(
      {
        "type": "m.room.message",
        "sender": "@example:example.org",
        "content": {},
        "origin_server_ts": 1612719080546,
        "unsigned": {
          "redacted_by": "$kACLXezKbvddldBNLWzLCSR5uwJDREXEpv_1f1QbZoE",
          "redacted_because": {
            "type": "m.room.redaction",
            "sender": "@example:example.org",
            "content": {},
            "redacts": "$NWgVNhcFbMnV2JBEj6H0odGV74N4w4KwyfYn9cWY58Q",
            "origin_server_ts": 1612719315996,
            "unsigned": {
              "age": 100221027
            },
            "event_id": "$kACLXezKbvddldBNLWzLCSR5uwJDREXEpv_1f1QbZoE"
          },
          "age": 100456477,
          "transaction_id": "1612719080.4721277.1"
        },
        "event_id": "$NWgVNhcFbMnV2JBEj6H0odGV74N4w4KwyfYn9cWY58Q"
      }
    ))

    event = event.as(Caridina::Events::RedactedMessage)
    event.origin_server_ts.should eq(1612719080546)
    event.room_id.should be_nil
    event.sender.should eq("@example:example.org")
    event.type.should eq("m.room.message")
  end
end
