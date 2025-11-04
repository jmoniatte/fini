module Presenters
  module Log
    class TerminalPresenter
      def self.render(logs)
        logs_by_day = logs.group_by { |log| log.logged_at.to_date }

        logs_by_day.keys.sort.reverse.each do |day|
          day_logs = logs_by_day[day]
          render_day(day, day_logs)
        end
      end

      def self.render_day(day, logs)
        day_duration = logs.map(&:duration).compact.sum

        puts [
          "#{day} - #{day.strftime('%A')}".red,
          Utilities.duration_string(day_duration).cyan
        ].join(" ")

        logs.each do |log|
          render_log(log)
        end
        puts ""
      end

      def self.render_log(log)
        parts = [
          "*",
          log.logged_at.strftime("%H:%M"),
          "-",
          log.text.bold
        ]
        parts << Utilities.duration_string(log.duration).cyan unless log.duration.nil?

        meta_string = format_metadata(log)
        parts << meta_string.grey.italic unless meta_string.nil?

        puts parts.compact.join(" ")
      end

      def self.format_metadata(log)
        meta_parts = []
        meta_parts << "+#{log.action}" unless log.action.nil?
        meta_parts << "@#{log.context}" unless log.context.nil?

        return nil if meta_parts.empty?

        "[#{meta_parts.join(' ')}]"
      end
    end
  end
end
