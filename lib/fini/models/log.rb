require_relative 'log/message_parser'

class Log < Sequel::Model

  def initialize(values = {})
    super
    if values[:message] && !values[:text]
      self.message = values[:message]
    end
  end

  def message=(msg)
    super
    parsed = Log::MessageParser.parse(msg)
    self.text = parsed[:text]
    self.action = parsed[:action]
    self.project = parsed[:project]
    self.duration = parsed[:duration]
  end

  # Create a log from a raw message string
  def self.create_from_message(message)
    create(
      message: message,
      done_at: Time.now.floor,
      created_at: Time.now.floor
    )
  end

  def to_s
    text
  end
end
