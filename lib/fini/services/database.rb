module Fini
  module Database
    # Get or create database connection (singleton pattern)
    # Automatically runs pending migrations on first connection
    def self.connection
      @connection ||= begin
        db_path = Fini.config['database_path']

        unless db_path
          raise Fini::ConfigurationError, "Missing 'database_path' in configuration"
        end

        connection_string = "sqlite://#{db_path}"
        db = Sequel.connect(connection_string)

        # Set as default database for Sequel::Model
        Sequel::Model.db = db

        # Automatically run pending migrations
        run_migrations(db)

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
