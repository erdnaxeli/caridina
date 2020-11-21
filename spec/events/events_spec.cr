require "./spec_helper"
require "../../src/events/events"

describe Caridina::Events::Event do
  it "serializes unknown events" do
    event = Caridina::Events::Event.from_json(%(
{
    "type": "m.unknown"
}
    ))

    unknown = event.as(Caridina::Events::Unknown)
    unknown.type.should eq("m.unknown")
    unknown.content.should be_nil
  end
end

describe Caridina::Events::CanonicalAlias do
  it "deserializes doc example" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "alias": "#somewhere:localhost",
        "alt_aliases": [
            "#somewhere:example.org",
            "#myroom:example.com"
        ]
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "",
    "type": "m.room.canonical_alias",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::CanonicalAlias)
    event.content.alias.should eq("#somewhere:localhost")
    event.content.alt_aliases.should eq(["#somewhere:example.org", "#myroom:example.com"])
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.origin_server_ts.should eq(1432735824653)
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("")
    event.type.should eq("m.room.canonical_alias")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end

describe Caridina::Events::Create do
  it "deserializes doc example" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "creator": "@example:example.org",
        "m.federate": true,
        "predecessor": {
            "event_id": "$something:example.org",
            "room_id": "!oldroom:example.org"
        },
        "room_version": "1"
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "",
    "type": "m.room.create",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::Create)
    event.content.creator.should eq("@example:example.org")
    event.content.m_federate.should be_true
    event.content.predecessor.should_not be_nil
    event.content.predecessor.try &.event_id.should eq("$something:example.org")
    event.content.predecessor.try &.room_id.should eq("!oldroom:example.org")
    event.content.room_version.should eq("1")
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.origin_server_ts.should eq(1432735824653)
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("")
    event.type.should eq("m.room.create")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end

describe Caridina::Events::JoinRules do
  it "deserializes doc example" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "join_rule": "public"
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "",
    "type": "m.room.join_rules",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::JoinRules)
    event.content.join_rule.should eq(Caridina::Events::JoinRules::JoinRule::Public)
    event.origin_server_ts.should eq(1432735824653)
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("")
    event.type.should eq("m.room.join_rules")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end

describe Caridina::Events::Member do
  it "deserializes doc example 1" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
        "displayname": "Alice Margatroid",
        "membership": "join"
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "@alice:example.org",
    "type": "m.room.member",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::Member)
    event.content.avatar_url.should_not be_nil
    event.content.avatar_url.try &.should eq("mxc://example.org/SEsfnsuifSDFSSEF")
    event.content.displayname.should_not be_nil
    event.content.displayname.try &.should eq("Alice Margatroid")
    event.content.membership.should eq(Caridina::Events::Member::Membership::Join)
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("@alice:example.org")
    event.type.should eq("m.room.member")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end

  it "deserializes doc example 2" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
        "displayname": "Alice Margatroid",
        "membership": "invite"
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "@alice:example.org",
    "type": "m.room.member",
    "unsigned": {
        "age": 1234,
        "invite_room_state": [
            {
                "content": {
                    "name": "Example Room"
                },
                "sender": "@bob:example.org",
                "state_key": "",
                "type": "m.room.name"
            },
            {
                "content": {
                    "join_rule": "invite"
                },
                "sender": "@bob:example.org",
                "state_key": "",
                "type": "m.room.join_rules"
            }
        ]
    }
}
    ))

    event = event.as(Caridina::Events::Member)
    event.content.avatar_url.should_not be_nil
    event.content.avatar_url.try &.should eq("mxc://example.org/SEsfnsuifSDFSSEF")
    event.content.displayname.should_not be_nil
    event.content.displayname.try &.should eq("Alice Margatroid")
    event.content.membership.should eq(Caridina::Events::Member::Membership::Invite)
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("@alice:example.org")
    event.type.should eq("m.room.member")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
    event.unsigned.try &.invite_room_state.should_not be_nil
    if invite_room_state = event.unsigned.try &.invite_room_state
      # TODO: test m.room_name content
      invite_room_state.size.should eq(2)
      invite_room_state[0].sender.should eq("@bob:example.org")
      invite_room_state[0].state_key.should eq("")
      invite_room_state[0].type.should eq("m.room.name")
      content = invite_room_state[1].content.as?(Caridina::Events::JoinRules::Content)
      content.should_not be_nil
      content.try &.join_rule.should eq(Caridina::Events::JoinRules::JoinRule::Invite)
      invite_room_state[1].sender.should eq("@bob:example.org")
      invite_room_state[1].state_key.should eq("")
      invite_room_state[1].type.should eq("m.room.join_rules")
    end
  end

  it "deserializes doc example 3" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
        "displayname": "Alice Margatroid",
        "membership": "invite",
        "third_party_invite": {
            "display_name": "alice",
            "signed": {
                "mxid": "@alice:example.org",
                "signatures": {
                    "magic.forest": {
                        "ed25519:3": "fQpGIW1Snz+pwLZu6sTy2aHy/DYWWTspTJRPyNp0PKkymfIsNffysMl6ObMMFdIJhk6g6pwlIqZ54rxo8SLmAg"
                    }
                },
                "token": "abc123"
            }
        }
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "@alice:example.org",
    "type": "m.room.member",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::Member)
    event.content.avatar_url.should_not be_nil
    event.content.avatar_url.try &.should eq("mxc://example.org/SEsfnsuifSDFSSEF")
    event.content.displayname.should_not be_nil
    event.content.displayname.try &.should eq("Alice Margatroid")
    event.content.membership.should eq(Caridina::Events::Member::Membership::Invite)
    event.content.third_party_invite.should_not be_nil
    event.content.third_party_invite.try &.display_name.should eq("alice")
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("@alice:example.org")
    event.type.should eq("m.room.member")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end

describe Caridina::Events::PowerLevels do
  it "deserializes doc example" do
    event = Caridina::Events::Event.from_json(%(
{
    "content": {
        "ban": 50,
        "events": {
            "m.room.name": 100,
            "m.room.power_levels": 100
        },
        "events_default": 0,
        "invite": 50,
        "kick": 50,
        "notifications": {
            "room": 20
        },
        "redact": 50,
        "state_default": 50,
        "users": {
            "@example:localhost": 100
        },
        "users_default": 0
    },
    "event_id": "$143273582443PhrSn:example.org",
    "origin_server_ts": 1432735824653,
    "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
    "sender": "@example:example.org",
    "state_key": "",
    "type": "m.room.power_levels",
    "unsigned": {
        "age": 1234
    }
}
    ))

    event = event.as(Caridina::Events::PowerLevels)
    event.content.ban.should eq(50)
    event.content.events.should eq({"m.room.name" => 100, "m.room.power_levels" => 100})
    event.content.events_default.should eq(0)
    event.content.invite.should eq(50)
    event.content.kick.should eq(50)
    event.content.notifications.should_not be_nil
    event.content.notifications.try &.room.should eq(20)
    event.content.redact.should eq(50)
    event.content.states_default.should eq(50)
    event.content.users.should eq({"@example:localhost" => 100})
    event.content.users_default.should eq(0)
    event.event_id.should eq("$143273582443PhrSn:example.org")
    event.room_id.should eq("!jEsUZKDJdhlrceRyVU:example.org")
    event.sender.should eq("@example:example.org")
    event.state_key.should eq("")
    event.type.should eq("m.room.power_levels")
    event.unsigned.should_not be_nil
    event.unsigned.try &.age.should eq(1234)
  end
end

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
