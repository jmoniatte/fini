module Fini
  class ConfigurationError < StandardError; end

  module Config
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
      if config['database_path']
        config['database_path'] = config['database_path'].gsub('~', Dir.home)
      end

      config
    end
  end
end
