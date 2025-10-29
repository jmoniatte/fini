module Database
  module Setup
    # Runs pending migrations
    def self.run_migrations
      Sequel.extension :migration
      migration_path = File.join(ROOT_PATH, 'database/migrate')
      return if Sequel::Migrator.is_current?(Fini.database, migration_path)

      Sequel::Migrator.run(Fini.database, migration_path)
    end

    # Auto-setup: initializes database and runs migrations (Sequel handles schema_info table automatically)
    def self.auto_setup
      # Ensure database is connected before running migrations
      Fini.database
      run_migrations
    end

    # Resets the database: drops all tables and re-runs migrations
    def self.reset
      tables = Fini.database.tables - [:schema_info]

      # Drop all tables
      tables.each do |table|
        Fini.database.drop_table(table)
      end

      # Drop schema_info to force re-running all migrations
      Fini.database.drop_table(:schema_info) if Fini.database.table_exists?(:schema_info)

      # Run all migrations
      run_migrations
    end
  end
end
