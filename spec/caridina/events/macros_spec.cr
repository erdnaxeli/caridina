require "json"

require "./spec_helper"

struct A
  include JSON::Serializable
  getter a : String
end

struct Ab
  include JSON::Serializable
  getter ab : String
end

struct B
  include JSON::Serializable
  getter b : String
end

struct C
  include JSON::Serializable
  getter c : String
end

struct D
  include JSON::Serializable
  getter d : String
end

struct Unknown
  include JSON::Serializable

  getter type : String
end

struct UniqueSimpleDiscriminator
  include JSON::Serializable

  caridina_use_json_discriminator({"type" => {"a" => A, "b" => B}})

  getter type : String
end

struct MultipleSimpleDiscriminator
  include JSON::Serializable

  caridina_use_json_discriminator(
    {
      "type"      => {"a" => A, "b" => B},
      "othertype" => {"c" => C, "d" => D},
    }
  )
end

struct IndirectDiscriminator
  include JSON::Serializable

  caridina_use_json_discriminator(
    {
      ["type", "subtype"] => {"a" => A, "b" => B},
    },
  )
end

struct ManyIndirectDiscriminator
  include JSON::Serializable

  caridina_use_json_discriminator(
    {
      ["type", "subtype"]                    => {"a" => A, "b" => B},
      ["othertype", "subtype", "subsubtype"] => {"b" => B, "c" => C, "d" => D},
    },
  )
end

struct Fallback
  include JSON::Serializable

  caridina_use_json_discriminator(
    {"type" => {"a" => A, "b" => B}},
    Unknown,
  )
end

struct UnionDiscriminator
  include JSON::Serializable

  caridina_use_json_discriminator(
    {
      "type" => {"a" => [A, Ab]},
    }
  )
end

abstract struct Complex
  include JSON::Serializable

  caridina_use_json_discriminator(
    {
      ["a", "b1", "c", "d2", "e"] => {"1": Result1, "2": Result2},
      ["type", "name"]            => {"2": Result2, "3": Result3},
    }
  )

  struct Type
    include JSON::Serializable

    getter name : String
  end

  struct A
    include JSON::Serializable

    struct B
      include JSON::Serializable

      struct C
        include JSON::Serializable

        struct D
          include JSON::Serializable

          getter e : String
        end

        getter d1 : D
        getter d2 : D
      end

      getter c : C
    end

    getter b1 : B
    getter b2 : B
  end

  struct Result1 < Complex
    include JSON::Serializable
  end

  struct Result2
    include JSON::Serializable
  end

  struct Result3
    include JSON::Serializable

    getter type : Type
  end

  getter type : Type?
  getter name : String
  getter a : A
end

describe "caridina_use_json_discriminator" do
  it "supports one simple discriminator" do
    r = UniqueSimpleDiscriminator.from_json(%(
{
  "type": "b",
  "b": "I am B"
}
))

    r = r.as(B)
    r.b.should eq("I am B")
  end

  it "supports many simple discriminators" do
    r = MultipleSimpleDiscriminator.from_json(%(
{
  "type": "b",
  "b": "I am B"
}
    ))

    r = r.as(B)
    r.b.should eq("I am B")

    r = MultipleSimpleDiscriminator.from_json(%(
{
  "othertype": "c",
  "c": "I am C"
}
    ))

    r = r.as(C)
    r.c.should eq("I am C")
  end

  it "deserializes when multiple discriminators match" do
    r = MultipleSimpleDiscriminator.from_json(%(
{
  "type": "a",
  "othertype": "d",
  "a": "a",
  "d": "d"
}
    ))

    r.is_a?(A | D).should_not be_nil
    if r.is_a?(A)
      r.a.should eq("a")
    elsif r.is_a?(D)
      r.d.should eq("d")
    end
  end

  it "supports indirect discriminator" do
    r = IndirectDiscriminator.from_json(%(
{
  "type": {
    "subtype": "a"
  },
  "a": "A"
}
    ))

    r = r.as(A)
    r.a.should eq("A")
  end

  it "supports going through objects to find discriminator" do
    r = ManyIndirectDiscriminator.from_json(%(
{
  "othertype": {
    "subtype": {
      "subsubtype": "d"
    }
  },
  "d": "D!"
}
    ))

    r = r.as(D)
    r.d.should eq("D!")
  end

  it "raises with incomplet indirect discriminator" do
    expect_raises(JSON::SerializableError) do
      ManyIndirectDiscriminator.from_json(%(
{
  "othertype": {
    "subnop": "nop"
  }
}
     ))
    end
  end

  it "deserialize testing all type before failing" do
    r = UnionDiscriminator.from_json(%(
      {
        "type": "a",
        "ab": "ab"
      }
    ))

    r = r.as(Ab)
    r.ab.should eq("ab")
  end

  it "deserialize complex example with optional discriminator" do
    r = Complex.from_json(%(
{
  "type": {
    "name": "3"
  }
}
    ))

    r = r.as(Complex::Result3)
    r.type.name.should eq("3")
  end

  it "deserialiwe complex example without loosing data" do
    r = Complex.from_json(%(
{
  "a": {
    "b1": {
      "c": {
        "d1": {
          "e": "f"
        },
        "d2": {
          "e": "1"
        }
      }
    },
    "b2": {
      "c": {
        "d1": {
          "e": "g"
        },
        "d2": {
          "e": "h"
        }
      }
    }
  },
  "name": "ugly json"
}
    ))

    r = r.as(Complex::Result1)
    r.a.b1.c.d1.e.should eq("f")
    r.a.b1.c.d2.e.should eq("1")
    r.a.b2.c.d1.e.should eq("g")
    r.a.b2.c.d2.e.should eq("h")
    r.name.should eq("ugly json")
  end

  it "does not stop when one discriminator is unknown" do
    r = Complex.from_json(%(
{
  "a": {
    "b1": {
      "c": {
        "d1": {
          "e": "f"
        },
        "d2": {
          "e": "unknown"
        }
      }
    },
    "b2": {
      "c": {
        "d1": {
          "e": "g"
        },
        "d2": {
          "e": "h"
        }
      }
    }
  },
  "name": "ugly json",
  "type": {
    "name": "2"
  }
}
    ))

    r.as(Complex::Result2)
  end

  it "respects discriminators priority" do
    r = Complex.from_json(%(
{
  "name": "ugly json",
  "type": {
    "name": "2"
  },
  "a": {
    "b1": {
      "c": {
        "d1": {
          "e": "f"
        },
        "d2": {
          "e": "1"
        }
      }
    },
    "b2": {
      "c": {
        "d1": {
          "e": "g"
        },
        "d2": {
          "e": "h"
        }
      }
    }
  }
}
    ))

    r.as(Complex::Result2)
  end

  it "keeps the last discriminator known value" do
    r = Complex.from_json(%(
{
  "a": {
    "b1": {
      "c": {
        "d1": {
          "e": "f"
        },
        "d2": {
          "e": "1"
        }
      }
    },
    "b2": {
      "c": {
        "d1": {
          "e": "g"
        },
        "d2": {
          "e": "h"
        }
      }
    }
  },
  "name": "ugly json",
  "type": {
    "name": "unknown"
  }
}
    ))

    r.as(Complex::Result1)
  end

  it "accepts a fallback" do
    r = Fallback.from_json(%(
{
  "type": "unknown"
}
    ))

    r = r.as(Unknown)
    r.type.should eq("unknown")
  end

  it "raises if the discriminator value is unknown and not fallback is provided" do
    expect_raises(JSON::SerializableError) do
      UniqueSimpleDiscriminator.from_json(%(
{
  "type": "unknown"
}
      ))
    end
  end
end
