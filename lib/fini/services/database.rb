module Fini
  class DatabaseError < StandardError; end

  module Database
    # Get or create database connection (singleton pattern)
    # Automatically runs pending migrations on first connection
    def self.connection
      @connection ||= begin
        db_path = Fini.config['database_path']

        # Connect to database
        connection_string = "sqlite://#{db_path}"
        begin
          db = Sequel.connect(connection_string)
        rescue Sequel::DatabaseConnectionError => e
          raise Fini::DatabaseError, "Cannot connect to database at #{db_path}: #{e.message}"
        rescue Sequel::DatabaseError => e
          raise Fini::DatabaseError, "Database error: #{e.message}"
        end

        # Set as default database for Sequel::Model
        Sequel::Model.db = db

        # Automatically run pending migrations
        begin
          run_migrations(db)
        rescue Sequel::Migrator::Error => e
          raise Fini::DatabaseError, "Migration failed: #{e.message}"
        rescue StandardError => e
          raise Fini::DatabaseError, "Error running migrations: #{e.message}"
        end

        db
      end
    end

    # Runs pending migrations
    def self.run_migrations(db = connection)
      Sequel.extension :migration
      migration_path = File.join(ROOT_PATH, 'database/migrate')
      return if Sequel::Migrator.is_current?(db, migration_path)

      Sequel::Migrator.run(db, migration_path)
    end

    # Resets the database: drops all tables and re-runs migrations
    def self.reset
      tables = connection.tables - [:schema_info]

      # Drop all tables
      tables.each do |table|
        connection.drop_table(table)
      end

      # Drop schema_info to force re-running all migrations
      connection.drop_table(:schema_info) if connection.table_exists?(:schema_info)

      # Run all migrations
      run_migrations
    end
  end
end
