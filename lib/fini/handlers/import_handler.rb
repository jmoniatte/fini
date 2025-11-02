module Fini
  class ImportHandler
    # Temp dev to import data from rlog file
    def self.process_file(file_path)
      counter = 0
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

        Log.create_from_message(
          log_message,
          DateTime.parse("#{log_date} #{log_time}")
        )
        counter += 1
        print "."
      end
      print "\n"
      counter
    end
  end
end
