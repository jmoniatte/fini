require 'yaml'
require 'json'
require 'date'
require 'fileutils'

require 'sequel'
require 'terminal-table'
require_relative 'fini/ansi_colors'

ROOT_PATH = File.expand_path('..', File.dirname(__FILE__))

# Load configuration module
require_relative 'fini/config'

module Fini
  # Custom error for configuration issues
  class ConfigurationError < StandardError; end

  class << self
    attr_accessor :config_path

    def config
      @config ||= Fini::Config.load(config_path)
    end

    def database
      @database ||= begin
        # Construct SQLite connection string from database_path
        db_path = config['database_path']

        unless db_path
          config_file = config_path || Fini::Config::DEFAULT_CONFIG_PATH
          raise ConfigurationError, "Missing 'database_path' in #{config_file}"
        end

        connection_string = "sqlite://#{db_path}"

        db = Sequel.connect(connection_string)
        # Set as default database for Sequel::Model
        Sequel::Model.db = db
        db
      end
    end
  end
end

# Load utilities and setup (but don't connect to DB yet)
require_relative '../database/setup'
require_relative 'fini/utilities'
require_relative 'fini/cli'
