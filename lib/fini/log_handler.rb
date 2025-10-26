module Fini
  class LogHandler
    # Creates a log from a message string
    # Example: "Worked on project two @2h #backend"
    def self.create(message)
      log = Log.create_from_message(message)

      # Return parsed data with the saved log record
      parsed = Log.parse_message(message)
      parsed.merge(log_id: log.id)
    end
  end
end
