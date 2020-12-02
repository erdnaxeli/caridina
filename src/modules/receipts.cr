module Caridina::Modules::Receipts
  enum Type
    Read

    def to_s
      case self
      in Type::Read
        "m.read"
      end
    end
  end

  def send_receipt(room_id : String, event_id : String, type = Type::Read) : Nil
    post("/rooms/#{room_id}/receipt/#{type}/#{event_id}")
  end
end
