require 'optparse'

module Fini
  class CLI
    def initialize(args)
      @args = args
      @mode = :default
      @days_count = 1
      @message = nil
      @config_path = nil
    end

    def run
      parse_options
      validate_options

      # Setup configuration
      begin
        Fini::Configuration.auto_setup(@config_path)
      rescue Fini::ConfigurationError => e
        puts "Configuration Error: #{e.message}".red
        exit 1
      end

      # Initialize database connection (runs migrations automatically)
      begin
        Fini::Database.connection
      rescue Fini::DatabaseError => e
        puts "Database Error: #{e.message}".red
        exit 1
      end

      # Load models and handlers now that we have a database connection
      require_relative 'models/log'
      require_relative 'handlers/log_handler'

      execute_command
    end

    private

    def create_option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: fini [options] [message]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-c", "--config PATH", "Path to custom config file (default: ~/.config/fini/config.yml)") do |path|
          @config_path = path
        end

        opts.on("-e", "--edit [DAYS]", Integer, "Edit logs for last N days (default: 1)") do |days|
          @mode = :edit
          @days_count = days || 1
        end

        opts.on("-v", "--view DAYS", Integer, "View logs for last N days (default: 1)") do |days|
          @mode = :view
          @days_count = days || 1
        end

        opts.on("-h", "--help", "Show this help message") do
          @mode = :help
        end

        opts.on("--reset", "Reset the database (deletes all data)") do
          @mode = :reset
        end

        opts.separator ""
        opts.separator "Commands:"
        opts.separator "    fini                              View today's logs"
        opts.separator "    fini -v 7                         View last 7 days' logs"
        opts.separator "    fini -e                           Edit today's logs"
        opts.separator "    fini -e 3                         Edit last 3 days' logs"
        opts.separator "    fini your message @2h @project    Log a message with duration and project"
        opts.separator ""
        opts.separator "Message format:"
        opts.separator "    @<duration>   Duration (examples: @30m, @1h, @1.5h, @1h45)"
        opts.separator "    @<project>    Project tag (examples: @backend, @front-end)"
        opts.separator "    +<action>     Action specifier (examples: +meeting, +code)"
        opts.separator "    action words: meeting, coding, writing, research, etc."
      end
    end

    def parse_options
      parser = create_option_parser

      begin
        parser.parse!(@args)
        # Remaining args become the message
        @message = @args.join(" ") unless @args.empty?
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        puts e.message.red
        puts parser.help
        exit 1
      end
    end

    def validate_options
      # No special validation needed for now
    end

    def execute_command
      system("clear") unless @mode == :help
      case @mode
      when :help
        puts create_option_parser.help
      when :reset
        reset_command
      when :edit
        edit_command
      when :view
        view_command
      when :default
        default_command
      end
    end

    def default_command
      if @message && !@message.empty?
        # Log a message
        Fini::LogHandler.create(@message)
      else
        # Show today's logs
        Fini::LogHandler.view_days(Date.today)
      end
    end

    def view_command
      start_date = Date.today
      end_date = Date.today - (@days_count - 1)
      Fini::LogHandler.view_days(start_date, end_date)
    end

    def edit_command
      start_date = Date.today
      end_date = Date.today - (@days_count - 1)
      Fini::LogHandler.edit_days(start_date, end_date)
    end

    def reset_command
      puts "WARNING: This will delete ALL data in the database!".red
      print "Type 'yes' to confirm: "
      confirmation = $stdin.gets.chomp

      if confirmation.downcase == 'yes'
        puts "\nResetting database...".yellow
        Fini::Database.reset
        puts "Database reset complete".green
      else
        puts "Database reset cancelled".yellow
      end
    end
  end
end
