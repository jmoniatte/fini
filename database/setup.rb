module Database
  module Setup
    # Runs pending migrations
    def self.run_migrations
      Sequel.extension :migration
      migration_path = File.join(ROOT_PATH, 'database/migrate')
      return if Sequel::Migrator.is_current?(DB, migration_path)

      Sequel::Migrator.run(DB, migration_path)
    end

    # Auto-setup: runs migrations (Sequel handles schema_info table automatically)
    def self.auto_setup
      run_migrations
    end

    # Resets the database: drops all tables and re-runs migrations
    def self.reset
      tables = DB.tables - [:schema_info]

      # Drop all tables
      tables.each do |table|
        DB.drop_table(table)
      end

      # Drop schema_info to force re-running all migrations
      DB.drop_table(:schema_info) if DB.table_exists?(:schema_info)

      # Run all migrations
      run_migrations
    end
  end
end
