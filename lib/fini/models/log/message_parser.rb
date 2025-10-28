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
      # TODO: needs to also parse 1h30
      pattern = /@\d+\.?\d*[mh]$/ # @90m @1.5h at the end of message
      text, duration = Utilities.extract_substring(message, pattern)

      match = duration&.strip&.match(/^@([\d.]+)([mh])$/)
      return [text, 0] unless match

      value = match[1].to_f
      unit = match[2]
      minutes = case unit
                when 'm'
                  value.to_i
                when 'h'
                  (value * 60).to_i
                else
                  0
                end
      [text, minutes]
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
