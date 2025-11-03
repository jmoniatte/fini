module Fini
  class ImportHandler
    # Temp dev to import data from rlog file
    def self.process_file(file_path)
      logs = []
      log_date = nil
      File.foreach(file_path) do |line|
        next if line.strip.empty?

        line = line.chomp
        if (match = line.match(/^# (\d{4}-\d{2}-\d{2})/))
          log_date = match[1]
          print "\n#{log_date}".red
          next
        end
        next if log_date.nil?

        if (match = line.match(/^\* (\d{2}:\d{2}) - (.+)$/))
          log_time = match[1]
          log_message = match[2]
        end
        next unless log_time && log_message

        logs << {
          message: log_message,
          logged_at: DateTime.parse("#{log_date} #{log_time}")
        }
        print "."
      end
      print "\n"

      puts "Creating #{logs.size} database records"

      logs.sort_by { |log| log[:logged_at] }.each do |log|
        Log.create_from_message(
          log[:message],
          log[:logged_at]
        )
        print "."
      end
      logs.size
    end
  end
end
