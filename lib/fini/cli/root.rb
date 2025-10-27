require 'thor'

module Fini
  module CLI
    class Root < Thor
      def self.exit_on_failure?
        true
      end

      desc "log MESSAGE", "Record a log message (default command)"
      def log(*message)
        full_message = message.join(' ')

        if full_message.empty?
          say("Error: No message provided".red)
          say("Usage: fini Your log message here @2h")
          exit(1)
        end

        # Parse and store the log message
        log = Fini::LogHandler.create(full_message)

        say("✓ Log recorded (ID: #{log.id})".green)
        say("  Text: #{log.text}")
        say("  Action: #{log.action}") if log.action
        say("  Duration: #{log.duration} minutes") if log.duration
        say("  Project: #{log.project}") if log.project
      end

      # Catch unknown commands and treat them as log messages
      def method_missing(method, *args)
        # Check if this is a valid Thor command first
        if self.class.all_commands.key?(method.to_s)
          super
        else
          # Reconstruct the full message including the "command" that was called
          full_message = [method.to_s, *args].join(' ')
          log(full_message)
        end
      end

      # Required when overriding method_missing
      def respond_to_missing?(method, _include_private = false)
        # Respond true only if it's NOT a valid Thor command
        !self.class.all_commands.key?(method.to_s)
      end

      desc "stats", "Display statistics"
      option :stats, aliases: "-s", desc: "Period to show stats for (today, week, month)"
      def stats
        say("\nStatistics".yellow)
        # WIP: Implement statistics display
        say("Period: #{options[:period] || 'all time'}")
      end

      desc "list", "List recent log entries"
      option :limit, aliases: "-n", type: :numeric, default: 10, desc: "Number of entries to show"
      def list
        say("\nRecent log entries (limit: #{options[:limit]})".yellow)
        # WIP: Implement listing logic
      end

      desc "reset", "Reset the database (WARNING: deletes all data)"
      def reset
        say("WARNING: This will delete ALL data in the database!".red)
        confirmation = ask("Type 'yes' to confirm:")

        if confirmation.downcase == 'yes'
          say "\nResetting database...".yellow
          Database::Setup.reset
          say "Database reset complete".green
        else
          say "Database reset cancelled".yellow
        end
      end
    end
  end
end
