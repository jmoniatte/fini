module Fini
  class LogHandler
    # Creates a log from a message string
    # Example: "Worked on project two @2h #backend"
    def self.create(message)
      log = Log.create_from_message(message)

      puts "✓ Log recorded (ID: #{log.id})".green
      puts "  Text: #{log.text}"
      puts "  Action: #{log.action}" if log.action
      puts "  Duration: #{log.duration} minutes" if log.duration
      puts "  Project: #{log.project}" if log.project

      log
    end

    def self.show_day(day: Time.now.to_date)
      range = day.to_time...(day.to_time + (24 * 60 * 60) - 1)
      logs = Log.where(logged_at: range)
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
        parts << Utilities.duration_string(log.duration).cyan
        parts << "@#{log.project}".italic unless log.project.nil?
        parts << "+#{log.action}".italic unless log.action.nil?
        puts parts.compact.join(" ")
      end
    end

    # WIP: extend to support multiple days (saving from tempfile lready does it)
    def self.edit_day(day: Time.now.to_date)
      require 'tempfile'

      range = day.to_time...(day.to_time + (24 * 60 * 60) - 1)
      logs = Log.where(logged_at: range).order(:logged_at)

      tempfile = Tempfile.new(['fini-edit-', '.md'])
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

      show_day(day: day)
      puts "✓ Logs updated for #{day}".green
    end
  end
end
