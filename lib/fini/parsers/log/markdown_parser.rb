require 'date'

module Parsers
  module Log
    class MarkdownParser
      # Parses markdown content and extracts log entries
      # Returns a hash with:
      #   - dates: array of dates found in the file
      #   - entries: array of hashes with logged_at and message
      def self.parse(content)
        lines = content.lines.reject { |line| line.strip.empty? }

        log_date = nil
        dates = []
        entries = []

        lines.each do |line|
          # Match date headers like "# 2025-11-03 - Monday"
          if (match = line.match(/^# (\d{4}-\d{2}-\d{2})/))
            log_date = match[1]
            dates << log_date
            next
          end

          next if log_date.nil?

          # Match log entries like "* 09:00 - message here"
          if (match = line.match(/^\* (\d{2}:\d{2}) - (.+)$/))
            log_time = match[1]
            log_message = match[2]

            logged_at = DateTime.parse("#{log_date} #{log_time}")
            entries << {
              logged_at: logged_at,
              message: log_message
            }
          end
        end

        {
          dates: dates,
          entries: entries
        }
      end
    end
  end
end
