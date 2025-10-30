require 'yaml'
require 'json'
require 'date'
require 'fileutils'

require 'sequel'
require 'terminal-table'

ROOT_PATH = File.expand_path('..', File.dirname(__FILE__))

require_relative 'fini/helpers/ansi_colors'
require_relative 'fini/helpers/utilities'
require_relative 'fini/services/config'
require_relative 'fini/services/database'
require_relative 'fini/cli'

module Fini
  # Custom error for configuration issues
  class ConfigurationError < StandardError; end

  class << self
    # Delegate to Config module
    def config
      Fini::Config.config
    end
  end
end
