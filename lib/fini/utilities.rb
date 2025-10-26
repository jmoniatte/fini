module Utilities
  def self.number_value(str)
    begin
      Float(str)
    rescue ArgumentError
      nil
    end
  end

  def self.date_value(str)
    begin
      Date.strptime(str, "%Y-%m-%d")
    rescue ArgumentError
      false
    end
  end

  module Cli
    def self.ask_value(cli, type, label, default = nil)
      value = nil
      until value
        entry = cli.ask("#{label}:", default: default)
        value = case type
                when :date
                  Utilities.date_value(entry)
                else
                  Utilities.number_value(entry)
                end
        cli.say("Enter a valid #{type} value".red) unless value
      end
      value
    end
  end

  module Number
    def self.delimited(number, precision = 2, suffix = '')
      return '' if number.nil?

      prefix = number < 0 ? "-" : ""
      parts = format("%.#{precision}f", number.abs).split('.')
      prefix + [
        parts[0].reverse.scan(/.{1,3}/).join(',').reverse,
        parts[1]
      ].compact.join('.') + suffix
    end

    def self.delimited_colored(number, precision = 2, suffix = '')
      return '' if number.nil?

      color = if number < 0
                :red
              elsif number == 0
                :white
              else
                :green
              end
      delimited(number.abs, precision, suffix).colorize(color)
    end
  end

  module Integer
    def self.delimited(number, suffix = '')
      Utilities::Number.delimited(number, 0, suffix)
    end

    def self.delimited_colored(number, suffix = '')
      Utilities::Number.delimited_colored(number, 0, suffix)
    end
  end
end
