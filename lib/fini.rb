require 'yaml'
require 'json'
require 'date'

require 'sequel'
require 'terminal-table'
require_relative 'fini/ansi_colors'

ROOT_PATH = File.expand_path('..', File.dirname(__FILE__))

# Load configuration module
require_relative 'fini/config'

CONFIG = Fini::Config.load

# Establish Sequel database connection
DB = Sequel.connect(CONFIG['database'])

# Load database setup utilities
require_relative '../database/setup'

# Run auto-setup on startup
Database::Setup.auto_setup

require_relative 'fini/utilities'
require_relative 'fini/log_handler'

require_relative 'fini/models/log'

# require_relative 'fini/views/account'

require_relative 'fini/cli'
