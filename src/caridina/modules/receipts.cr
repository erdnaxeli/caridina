# [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#id53)
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

  # Sends a receipt.
  #
  # The only available type so far is a read receipt.
  #
  # [Matrix API](https://matrix.org/docs/spec/client_server/r0.6.1#post-matrix-client-r0-rooms-roomid-receipt-receipttype-eventid)
  def send_receipt(room_id : String, event_id : String, type = Type::Read) : Nil
    post("/rooms/#{room_id}/receipt/#{type}/#{event_id}")
  end
end
