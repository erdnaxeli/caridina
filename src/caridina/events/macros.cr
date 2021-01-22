# `JSON::Serializable::use_json_discriminator` on steroids.
#
# It supports looking at many fields to discriminate the type, and case use nested
# fields. If no known discriminator value is found, it use the fallback type if any
# or raise an error.
#
# The mapping should be order by priority, in case many discriminator values are
# found, higher priority last.
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
# If many discriminator fields match, the last one with a known value will be used.
#
# ```
# Event.from(%(
#   {
#     "type": {"name": "unknown"},
#     "event_type": "C"
#   }
# )) # => EventC(…)
#
# Event.from(%(
#   {
#     "type": {"name": "A"},
#     "event_type": "unknown"
#   }
# )) # => EventA(…)
#
# # "event_type" is read first, but in the mapping ["type", "name"] came last so
# # it has priority.
# Event.from(%(
#   {
#     "event_type": "C",
#     "type": {"name": "A"}
#   }
# )) # => EventA(…)
macro caridina_use_json_discriminator(mapping, fallback = nil)
  {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
    {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
  {% end %}

  def self.new(pull : ::JSON::PullParser)
    location = pull.location

    # Array of tuples(field name, discriminator value)
    discriminators = Array(Tuple(String | Array(String), String)).new

    # We read the JSON to find discriminators fields, while also rebuiding it
    # to give it to the final type.
    json = String.build do |io|
      JSON.build(io) do |builder|
        builder.start_object
        pull.read_object do |key|
          # We try to match the key to a discriminator field
          case key
            {% for field in mapping.keys %}
              {% if field.is_a?(ArrayLiteral) %}
                when {{field[0].id.stringify}}
                  field_name = [{{field[0]}}]

                  # If the field is an array, we construct nested `cases` blocks.
                  {% for subfield, index in field %}
                    {% if index != 0 %}
                      builder.field(key) do
                        builder.start_object
                        pull.read_object do |key|
                          case key
                          when {{subfield.id.stringify}}
                            # We construct the field's fully qualified name,
                            # with all the nested fields.
                            field_name << {{subfield.id.stringify}}
                    {% end %}
                  {% end %}

                  # We come here if we matched a full nested discriminator. We
                  # save the value and the field's fully qualified name.
                  value = pull.read_string
                  builder.field(key, value)
                  discriminators << {field_name, value}

                  # We need to do a second loop to write all the `else` clauses
                  # and close all the `case` blocks.
                  {% for f, index in field %}
                    {% if index != 0 %}
                          else
                            # We save the raw json at for each non matched field.
                            builder.field(key) { pull.read_raw(builder) }
                          end
                        end
                        builder.end_object
                      end
                    {% end %}
                  {% end %}
              {% else %}
                # If the field is not an array, we just try to match it.
                when {{field.id.stringify}}
                  value = pull.read_string
                  builder.field(key, value)
                  discriminators << {key, value}
              {% end %}
            {% end %}
            else
              # We save the raw json at for each non matched field.
              builder.field(key) { pull.read_raw(builder) }
            end
        end
        builder.end_object
      end
    end

    fields = {{mapping.keys.id}}
    unless discriminators.size
      raise ::JSON::MappingError.new("JSON is missing one of discriminator fields: #{fields}", to_s, nil, *location, nil)
    end

    # Order the discriminators found by priority, higher priority first.
    discriminators.sort_by! { |x| fields.index(x[0]) || 0 }.reverse!
    # For each discriminator found, we match its field name (this can't fail),
    # then we try to match the field's value.
    discriminators.each do |field_name, discriminator_value|
      case field_name
      {% for field_key, field_mapping in mapping %}
        when {{field_key}}
          case discriminator_value
          {% for key, value in mapping[field_key] %}
            when {{key.id.stringify}}
              # We found a valid discriminator value, we can stop here.
              return {{value.id}}.from_json(json)
          {% end %}
          end
      {% end %}
      else
        raise Exception.new("This can't happen")
      end
    end

    # If we did not return at this point, it means no discriminator value matched.
    {% if fallback %}
      {{fallback.id}}.from_json(json)
    {% else %}
      raise ::JSON::MappingError.new("Unknown discriminators #{discriminators.inspect}", to_s, nil, *location, nil)
    {% end %}
  end
end