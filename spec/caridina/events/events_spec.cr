require "./spec_helper"

describe Caridina::Events::Event do
  it "serializes unknown events" do
    event = Caridina::Events::Event.from_json(%(
{
    "type": "m.unknown"
}
    ))

    unknown = event.as(Caridina::Events::Unknown)
    unknown.type.should eq("m.unknown")
  end
end

