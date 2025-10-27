module Fini
  class LogHandler
    # Creates a log from a message string
    # Example: "Worked on project two @2h #backend"
    def self.create(message)
      Log.create_from_message(message)
    end
  end
end
