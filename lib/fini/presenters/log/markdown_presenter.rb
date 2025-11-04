module Presenters
  module Log
    class MarkdownPresenter
      def self.render(logs)
        logs_by_day = logs.group_by { |log| log.logged_at.to_date }

        output = []
        logs_by_day.keys.sort.reverse.each do |day|
          day_logs = logs_by_day[day].sort_by(&:logged_at)
          output << render_day(day, day_logs)
        end

        output.join("\n")
      end

      def self.render_day(day, logs)
        lines = []
        lines << "# #{day} - #{day.strftime('%A')}"

        logs.each do |log|
          lines << render_log(log)
        end

        lines << "" # Empty line between days
        lines.join("\n")
      end

      def self.render_log(log)
        parts = [
          "*",
          log.logged_at.strftime("%H:%M"),
          "-",
          log.message
        ]
        parts.join(" ")
      end
    end
  end
end
