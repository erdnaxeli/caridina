require "spec"
require "../src/caridina"


SYNC = %(
  {
    "next_batch": "s72595_4483_1934",
    "presence": {
      "events": [
        {
          "content": {
            "avatar_url": "mxc://localhost:wefuiwegh8742w",
            "last_active_ago": 2478593,
            "presence": "online",
            "currently_active": false,
            "status_msg": "Making cupcakes"
          },
          "type": "m.presence",
          "sender": "@example:localhost"
        }
      ]
    },
    "account_data": {
      "events": [
        {
          "type": "org.example.custom.config",
          "content": {
            "custom_config_key": "custom_config_value"
          }
        }
      ]
    },
    "rooms": {
      "join": {
        "!726s6s6q:example.com": {
          "summary": {
            "m.heroes": [
              "@alice:example.com",
              "@bob:example.com"
            ],
            "m.joined_member_count": 2,
            "m.invited_member_count": 0
          },
          "state": {
            "events": [
              {
                "content": {
                  "membership": "join",
                  "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
                  "displayname": "Alice Margatroid"
                },
                "type": "m.room.member",
                "event_id": "$143273582443PhrSn:example.org",
                "room_id": "!726s6s6q:example.com",
                "sender": "@example:example.org",
                "origin_server_ts": 1432735824653,
                "unsigned": {
                  "age": 1234
                },
                "state_key": "@alice:example.org"
              }
            ]
          },
          "timeline": {
            "events": [
              {
                "content": {
                  "membership": "join",
                  "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
                  "displayname": "Alice Margatroid"
                },
                "type": "m.room.member",
                "event_id": "$143273582443PhrSn:example.org",
                "room_id": "!726s6s6q:example.com",
                "sender": "@example:example.org",
                "origin_server_ts": 1432735824653,
                "unsigned": {
                  "age": 1234
                },
                "state_key": "@alice:example.org"
              },
              {
                "content": {
                  "body": "This is an example text message",
                  "msgtype": "m.text",
                  "format": "org.matrix.custom.html",
                  "formatted_body": "<b>This is an example text message</b>"
                },
                "type": "m.room.message",
                "event_id": "$143273582443PhrSn:example.org",
                "room_id": "!726s6s6q:example.com",
                "sender": "@example:example.org",
                "origin_server_ts": 1432735824653,
                "unsigned": {
                  "age": 1234
                }
              }
            ],
            "limited": true,
            "prev_batch": "t34-23535_0_0"
          },
          "ephemeral": {
            "events": [
              {
                "content": {
                  "user_ids": [
                    "@alice:matrix.org",
                    "@bob:example.com"
                  ]
                },
                "type": "m.typing",
                "room_id": "!jEsUZKDJdhlrceRyVU:example.org"
              }
            ]
          },
          "account_data": {
            "events": [
              {
                "content": {
                  "tags": {
                    "u.work": {
                      "order": 0.9
                    }
                  }
                },
                "type": "m.tag"
              },
              {
                "type": "org.example.custom.room.config",
                "content": {
                  "custom_config_key": "custom_config_value"
                }
              }
            ]
          }
        }
      },
      "invite": {
        "!696r7674:example.com": {
          "invite_state": {
            "events": [
              {
                "sender": "@alice:example.com",
                "type": "m.room.name",
                "state_key": "",
                "content": {
                  "name": "My Room Name"
                }
              },
              {
                "sender": "@alice:example.com",
                "type": "m.room.member",
                "state_key": "@bob:example.com",
                "content": {
                  "membership": "invite"
                }
              }
            ]
          }
        }
      },
      "leave": {}
    }
  }
)
