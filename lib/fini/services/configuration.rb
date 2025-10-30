module Fini
  class ConfigurationError < StandardError; end

  module Configuration
    DEFAULT_CONFIG_PATH = File.expand_path('~/.config/fini/config.yml')

    class << self
      attr_reader :config

      # Auto-setup: ensures config exists and loads it
      def auto_setup(path = nil)
        if path.nil?
          path = DEFAULT_CONFIG_PATH
          unless File.exist?(path)
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.cp(
              File.join(ROOT_PATH, 'config.yml'),
              DEFAULT_CONFIG_PATH
            )
          end
        else
          path = File.expand_path(path) # Expand relative paths and ~
        end

        begin
          @config = load(path)
        rescue Errno::ENOENT
          raise Fini::ConfigurationError, "file not found at #{path}"
        rescue Errno::EACCES
          raise Fini::ConfigurationError, "file #{path} unreadable"
        rescue Psych::SyntaxError => e
          raise Fini::ConfigurationError, "invalid YAML in #{path}: #{e.message}"
        end
      end
    end

    def self.load(path)
      config = YAML.safe_load(File.read(path))

      unless config.is_a?(Hash)
        raise Fini::ConfigurationError, "file must contain a YAML hash, got #{config.class}"
      end

      unless config['database_path']
        raise Fini::ConfigurationError, "database path is not specified in #{path}"
      end

      # Expand ~ in database_path
      config['database_path'] = config['database_path'].gsub('~', Dir.home)

      # Validate database path
      validate_database_path(config['database_path'])

      config
    end

    def self.validate_database_path(db_path)
      # Check if path is actually a directory
      if File.directory?(db_path)
        raise Fini::ConfigurationError, "database_path points to a directory: #{db_path}"
      end

      db_dir = File.dirname(db_path)

      # If directory exists, check permissions
      if Dir.exist?(db_dir)
        unless File.writable?(db_dir)
          raise Fini::ConfigurationError, "No write permission for database directory: #{db_dir}"
        end
      else
        # Try to create directory structure
        begin
          FileUtils.mkdir_p(db_dir)
        rescue Errno::EACCES
          raise Fini::ConfigurationError, "Cannot create database directory #{db_dir}: permission denied"
        rescue Errno::EROFS
          raise Fini::ConfigurationError, "Cannot create database directory #{db_dir}: read-only filesystem"
        rescue SystemCallError => e
          raise Fini::ConfigurationError, "Cannot create database directory #{db_dir}: #{e.message}"
        end
      end
    end
  end
end
