require 'sequel'
require 'yaml'
require 'date'
require 'securerandom'

MIGRATION_PATH = 'database/migrate'.freeze
DUMP_PATH = 'database/schema.sql'.freeze
CONFIG = YAML.safe_load(File.read('config.yml'))
ROOT_PATH = File.expand_path('.', __dir__)

# Establish Sequel database connection
DB = Sequel.connect(CONFIG['database'])

# Load database setup utilities
require_relative 'database/setup'

namespace :db do
  task :migrate do
    Database::Setup.run_migrations
    puts "Migrations complete!"
  end

  task :reset do
    Database::Setup.reset
    puts "Database reset complete!"
  end

  task :rollback do
    Sequel.extension :migration
    current_version = DB[:schema_info].get(:version)

    if current_version && current_version > 0
      target_version = current_version - 1
      Sequel::Migrator.run(DB, MIGRATION_PATH, target: target_version)
      puts "Rolled back to version #{target_version}"
    else
      puts "No migrations to roll back"
    end
  end

  task :dump_schema do
    # Extract database path from Sequel connection string
    db_path = CONFIG['database'].sub('sqlite://', '')
    `sqlite3 #{db_path} .schema > #{DUMP_PATH}`

    puts "Schema dumped into #{DUMP_PATH}."
  end

  task :backup do
    backup_file = File.join(
      CONFIG['application']['data_path'],
      'backup',
      "#{Date.today.strftime('%Y-%m-%d')}-#{SecureRandom.alphanumeric(6)}.sqlite3"
    )

    # Extract database path from Sequel connection string
    db_path = CONFIG['database'].sub('sqlite://', '')
    `sqlite3 #{db_path} ".backup #{backup_file}"`

    puts "Backup created at #{backup_file}."
  end
end
