require 'yaml'
require 'json'
require 'date'
require 'fileutils'

require 'sequel'
require 'terminal-table'

ROOT_PATH = File.expand_path('..', File.dirname(__FILE__))

require_relative 'fini/helpers/ansi_colors'
require_relative 'fini/helpers/utilities'
require_relative 'fini/services/configuration'
require_relative 'fini/services/database'
require_relative 'fini/cli'

module Fini
  class << self
    # Delegate to Configuration module
    def configuration
      Fini::Configuration.config
    end
  end
end
