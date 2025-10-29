require_relative '../../utilities'

class Log < Sequel::Model
  module MessageParser
    # Parses and extracts attributes from message
    def self.parse(message)
      text, duration = parse_duration(message)
      text, action = parse_action(text)
      text, project = parse_project(text)

      {
        text: text,
        duration: duration,
        action: action,
        project: project
      }
    end

    def self.parse_duration(message)
      # Matches: @30m, @2h, @1.5h, @1h30, @1h30m (anywhere in string)
      # Order matters: try combined format first, then simple format
      pattern = /@(?:\d+h\d+m?|\d+\.?\d*[hm])/
      text, duration = Utilities.extract_substring(message, pattern)

      return [text, nil] unless duration

      match = duration.strip.match(/^@(?:(\d+\.?\d*)h)?(\d+)?m?$/)
      return [text, nil] unless match

      hours = match[1]&.to_f || 0
      mins = match[2].to_i || 0

      total_minutes = (hours * 60).to_i + mins
      [text, total_minutes]
    end

    def self.parse_action(message)
      pattern = /(^| )\+[A-Za-z]+/ # +code +meet
      text, action = Utilities.extract_substring(message, pattern)
      if action
        action = action&.tr("+", "")
        return [text, action]
      end

      [message, infer_attribute("action", message)]
    end

    def self.parse_project(message)
      pattern = /(^| )@[A-Za-z0-9_-]*/ # @project-name
      text, project = Utilities.extract_substring(message, pattern)
      if project
        project = project.tr("@ ", "")
        return [text, project]
      end
      [message, infer_attribute("project", message)]
    end

    # Fallback to attribute inference from configuration
    def self.infer_attribute(attribute, message)
      rules = CONFIG['infer_rules'][attribute] || {}
      rules.each do |key, patterns|
        patterns&.each do |pattern|
          return key if message.match?(Regexp.new(pattern))
        end
      end
      nil
    end
  end
end
