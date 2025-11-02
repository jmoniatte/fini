require_relative '../../helpers/utilities'

class Log < Sequel::Model
  module MessageParser
    DURATION_PATTERN = /@(?:\d+h\d+m?|\d+\.?\d*[hm])/.freeze
    CONTEXT_PATTERN = /@[A-Za-z0-9_-]+/.freeze
    ACTION_PATTERN = /\+[A-Za-z]+/.freeze

    # Parses and extracts attributes from message
    # Two-phase approach: extract pattern first, fallback to rules
    def self.parse(message)
      text = message.dup
      text, duration = extract_pattern(text, DURATION_PATTERN) do |match|
        parse_duration_value(match)
      end
      text, context = extract_pattern(text, CONTEXT_PATTERN) do |match|
        match.delete('@')
      end
      text, action = extract_pattern(text, ACTION_PATTERN) do |match|
        match.delete('+')
      end

      # Fallback to inference
      action ||= infer_attribute("action", message)
      context ||= infer_attribute("context", message)

      {
        text: text.gsub(/\s{2,}/, ' ').strip,
        duration: duration,
        action: action,
        context: context
      }
    end

    # Extract suffix: remove completely from end
    def self.extract_pattern(text, pattern)
      match = text.match(pattern)
      return [text, nil] unless match

      value = yield(match[0])
      new_text = text.sub(pattern, '').strip
      [new_text, value]
    end

    # Parse duration value from matched string
    def self.parse_duration_value(duration_str)
      match = duration_str.match(/^@?(?:(\d+\.?\d*)h)?(\d+)?m?$/)
      return nil unless match

      hours = match[1]&.to_f || 0
      mins = match[2].to_i || 0
      total = (hours * 60).to_i + mins
      total > 0 ? total : nil
    end

    # Fallback to attribute inference from configuration
    def self.infer_attribute(attribute, message)
      return nil unless (config_attribute = Fini.configuration[attribute])

      if (rules = config_attribute["rules"])
        rules.each do |key, patterns|
          patterns&.each do |pattern|
            next if pattern.nil?
            return key if message.match?(Regexp.new(pattern))
          end
        end
      end
      config_attribute["default"]
    end
  end
end
