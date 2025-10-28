require 'optparse'

module Fini
  class CLI
    def initialize(args)
      @args = args
      @mode = :default
      @edit = false
      @message = nil
    end

    def run
      parse_options
      validate_options
      execute_command
    end

    private

    def create_option_parser
      OptionParser.new do |opts|
        opts.banner = "Usage: fini [options] [message]"
        opts.separator ""
        opts.separator "Options:"

        opts.on("-e", "--edit", "Edit today's logs") do
          @edit = true
        end

        opts.on("-h", "--help", "Show this help message") do
          @mode = :help
        end

        opts.on("--reset", "Reset the database (deletes all data)") do
          @mode = :reset
        end

        opts.separator ""
        opts.separator "Commands:"
        opts.separator "    fini                              Show today's logs"
        opts.separator "    fini -e                           Edit today's logs"
        opts.separator "    fini your message @2h #project    Log a message with duration and project"
        opts.separator ""
        opts.separator "Message format:"
        opts.separator "    @<duration>   Duration (e.g., @2h, @30m, @1.5hours)"
        opts.separator "    #<project>    Project tag (e.g., #backend)"
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
      case @mode
      when :help
        puts create_option_parser.help
      when :reset
        reset_command
      when :default
        default_command
      end
    end

    def default_command
      if @message && !@message.empty?
        # Log a message
        Fini::LogHandler.create(@message)
      elsif @edit
        # Edit today's logs
        Fini::LogHandler.edit_day
      else
        # Show today's logs
        Fini::LogHandler.show_day
      end
    end

    def reset_command
      puts "WARNING: This will delete ALL data in the database!".red
      print "Type 'yes' to confirm: "
      confirmation = $stdin.gets.chomp

      if confirmation.downcase == 'yes'
        puts "\nResetting database...".yellow
        Database::Setup.reset
        puts "Database reset complete".green
      else
        puts "Database reset cancelled".yellow
      end
    end
  end
end
