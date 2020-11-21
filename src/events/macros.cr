# `JSON::Serializable::use_json_discriminator` on steroids.
#
# It supports looking at many fields to discriminate the type. It can also look
# in a child object's field.
#
# If a fallback type is provided, it uses it to deserialize the given json instead
# of raising when the the discriminator value is unknown.
#
# For example:
#
# ```
# struct Event
#   include JSON::Serializable
#
#   caridina_use_json_discriminator(
#     {
#       ["type", "name"] => {"A": EventA, "B": EventB},
#       "event_type"     => {"A": EventA, "C": EventC},
#     }
#   )
#
#   struct Type
#     include JSON::Serializable
#
#     getter name : String
#   end
#
#   getter type : Type
#   getter event_type : String
# end
#
# Event.from_json(%(
#   {
#     "type": {"name": "A"},
#     ...
#   }
# )) # => EventA(…)
#
# Event.from_json(%(
#   {
#     "event_type": "C",
#     ...
#   }
# )) # => EventC(…)
# ```
#
# You MUST use an array when using a nested field as a discriminator field. There
# is no limit on the level of nesting.
#
# If many discriminator fields match, which one will be used is not guaranteed.
macro caridina_use_json_discriminator(mapping, fallback = nil)
  {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
    {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
  {% end %}

  def self.new(pull : ::JSON::PullParser)
    location = pull.location

    field_name = nil
    discriminator_value = nil

    # Try to find the discriminator while also getting the raw
    # string value of the parsed JSON, so then we can pass it
    # to the final type.
    json = String.build do |io|
      JSON.build(io) do |builder|
        builder.start_object
        pull.read_object do |key|
          case key
            {% for field in mapping.keys %}
              {% if field.is_a?(ArrayLiteral) %}
                when {{field[0].id.stringify}}
                  tmp_field_name = [{{field[0]}}]

                  {% for subfield, index in field %}
                    {% if index != 0 %}
                      builder.field(key) do
                        builder.start_object
                        pull.read_object do |key|
                          case key
                          when {{subfield.id.stringify}}
                            tmp_field_name << {{subfield.id.stringify}}
                    {% end %}
                  {% end %}

                  field_name = tmp_field_name
                  discriminator_value = pull.read_string
                  builder.field(key, discriminator_value)

                  {% for f, index in field %}
                    {% if index != 0 %}
                          else
                            builder.field(key) { pull.read_raw(builder) }
                          end
                        end
                        builder.end_object
                      end
                    {% end %}
                  {% end %}
              {% else %}
                when {{field.id.stringify}}
                  field_name = {{field.id.stringify}}
                  discriminator_value = pull.read_string
                  builder.field(key, discriminator_value)
              {% end %}
            {% end %}
            else
              builder.field(key) { pull.read_raw(builder) }
            end
        end
        builder.end_object
      end
    end

    unless discriminator_value
      fields = {{mapping.keys.id}}
      raise ::JSON::MappingError.new("JSON is missing one of discriminator fields: #{fields}", to_s, nil, *location, nil)
    end

    case field_name
    {% for field_key, field_mapping in mapping %}
      when {{field_key}}
        case discriminator_value
        {% for key, value in mapping[field_key] %}
          when {{key.id.stringify}}
            {{value.id}}.from_json(json)
        {% end %}
        else
          {% if fallback %}
            {{fallback.id}}.from_json(json)
          {% else %}
            raise ::JSON::MappingError.new("Unknown '#{field_name}' discriminator value: #{discriminator_value.inspect}", to_s, nil, *location, nil)
          {% end %}
        end
    {% end %}
    else
      raise Exception.new("This can't happen")
    end
  end
end
