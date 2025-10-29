require_relative '../../utilities'

class Log < Sequel::Model
  module MessageParser
    DURATION_PATTERN = /@(?:\d+h\d+m?|\d+\.?\d*[hm])/.freeze
    DURATION_AT_END_PATTERN = /#{DURATION_PATTERN.source}$/.freeze

    ACTION_PATTERN = /\+[A-Za-z]+/.freeze
    ACTION_AT_END_PATTERN = /#{ACTION_PATTERN.source}$/.freeze

    PROJECT_PATTERN = /@[A-Za-z0-9_-]+/.freeze

    # Parses and extracts attributes from message
    # Two-phase approach: extract suffix first, then inline
    # Project is always kept in text (only prefix stripped)
    def self.parse(message)
      text = message.dup

      # Extract suffix first (remove completely)
      text, duration = extract_suffix(text, DURATION_AT_END_PATTERN) do |match|
        parse_duration_value(match)
      end

      text, action = extract_suffix(text, ACTION_AT_END_PATTERN) do |match|
        match.delete('+')
      end

      # If not found as suffix, extract inline (keep in text without prefix)
      unless duration
        text, duration = extract_inline(text, DURATION_PATTERN) do |match|
          parse_duration_value(match)
        end
      end
      unless action
        text, action = extract_inline(text, ACTION_PATTERN) do |match|
          match.delete('+')
        end
      end

      # Project is always extracted inline (always kept in text without @)
      text, project = extract_inline(text, PROJECT_PATTERN) { |m| m.delete('@') }

      # Fallback to inference
      action ||= infer_attribute("action", message)
      project ||= infer_attribute("project", message)

      {
        text: text.strip,
        duration: duration,
        action: action,
        project: project
      }
    end

    # Extract suffix: remove completely from end
    def self.extract_suffix(text, pattern)
      match = text.match(pattern)
      return [text, nil] unless match

      value = yield(match[0])
      new_text = text.sub(pattern, '').strip
      [new_text, value]
    end

    # Extract inline: keep in text without prefix
    def self.extract_inline(text, pattern)
      match = text.match(pattern)
      return [text, nil] unless match

      value = yield(match[0])
      without_prefix = match[0].delete('@+')
      new_text = text.sub(match[0], without_prefix)
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
      rules = Fini.config['infer_rules'][attribute] || {}
      rules.each do |key, patterns|
        patterns&.each do |pattern|
          return key if message.match?(Regexp.new(pattern))
        end
      end
      nil
    end
  end
end
