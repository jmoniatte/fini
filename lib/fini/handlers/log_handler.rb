module Fini
  class LogHandler
    # Creates a log from a message string
    # Example: "Worked on project two @2h #backend"
    def self.create(message)
      log = Log.create_from_message(message)
      view_days(log.logged_at.to_date)
      log
    end

    def self.view_days(start_date, end_date = nil)
      end_date ||= start_date
      start_date, end_date = end_date, start_date if start_date < end_date

      start_date.downto(end_date).each do |day|
        range = day.to_time...(day.to_time + (24 * 60 * 60) - 1)
        logs = Log.where(logged_at: range)

        # Skip days with no entries
        next if logs.empty?

        day_duration = logs.map(&:duration).compact.sum

        puts [
          "#{day} - #{day.strftime('%A')}".red,
          Utilities.duration_string(day_duration).cyan
        ].join(" ")

        logs.each do |log|
          parts = [
            "*",
            log.logged_at.strftime("%H:%M"),
            "-",
            log.text.bold
          ]
          parts << Utilities.duration_string(log.duration).cyan unless log.duration.nil?
          parts << "@#{log.project}".grey.italic unless log.project.nil?
          parts << "+#{log.action}".grey.italic unless log.action.nil?
          puts parts.compact.join(" ")
        end
        puts ""
      end
    end

    def self.edit_days(start_date, end_date = nil)
      require 'tempfile'

      end_date ||= start_date
      start_date, end_date = end_date, start_date if start_date < end_date

      tempfile = Tempfile.new(['fini-edit-', '.md'])

      # Generate sections for each day (newest first)
      start_date.downto(end_date).each do |day|
        range = day.to_time...(day.to_time + (24 * 60 * 60) - 1)
        logs = Log.where(logged_at: range).order(:logged_at)

        tempfile.puts "# #{day} - #{day.strftime('%A')}"
        logs.each do |log|
          parts = [
            "*",
            log.logged_at.strftime("%H:%M"),
            "-",
            log.message
          ]
          tempfile.puts parts.join(" ")
        end
        tempfile.puts "" # Empty line between days
      end

      tempfile.close

      # Open in editor
      editor = ENV['EDITOR'] || 'vim'
      system("#{editor} #{tempfile.path}")

      # Read back and update logs
      updated_lines = File.readlines(tempfile.path).reject { |line| line.strip.empty? }

      log_date = nil

      # file_dates for database records to delete
      # new_logs for the logs to create
      file_dates = []
      new_lines = []
      updated_lines.each do |line|
        if (match = line.match(/^# (\d{4}-\d{2}-\d{2})/))
          log_date = match[1]
          file_dates << log_date
          next
        end
        next if log_date.nil?

        if (match = line.match(/^\* (\d{2}:\d{2}) - (.+)$/))
          log_time = match[1]
          log_message = match[2]
        end
        next unless log_time && log_message

        logged_at = DateTime.parse("#{log_date} #{log_time}")
        new_lines << {
          logged_at: logged_at,
          message: log_message
        }
      end

      return if file_dates.empty?

      file_dates.each do |file_date|
        # Delete all database records for that day
        date = Date.parse(file_date)
        range = date.to_time...(date.to_time + (24 * 60 * 60))
        Log.where(logged_at: range).delete
      end

      # Create new logs from edited content
      new_lines.each do |line|
        Log.create_from_message(line[:message], line[:logged_at])
      end

      tempfile.unlink

      # Show updated logs for the date range
      view_days(start_date, end_date)
      if start_date == end_date
        puts "✓ Logs updated for #{start_date}".green
      else
        puts "✓ Logs updated for #{end_date} to #{start_date}".green
      end
    end
  end
end
