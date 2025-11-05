require_relative 'log/message_parser'

class Log < Sequel::Model
  # Create a log from a raw message string
  def self.create_from_message(message, logged_at = nil)
    parsed = Log::MessageParser.parse(message)
    create(
      logged_at: logged_at || Time.now.floor(0),
      message: message,
      text: parsed[:text],
      action: parsed[:action],
      context: parsed[:context],
      duration: parsed[:duration],
      created_at: Time.now.floor(0)
    )
  end

  def reprocess
    parsed = Log::MessageParser.parse(message)
    update(
      text: parsed[:text],
      action: parsed[:action],
      context: parsed[:context],
      duration: parsed[:duration]
    )
  end

  def to_s
    text
  end
end
