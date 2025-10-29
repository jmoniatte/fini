module Fini
  module Config
    DEFAULT_CONFIG_PATH = File.expand_path('~/.config/fini/config.yml')

    # Load configuration with user overrides
    # Accepts optional config_path for custom config file location
    def self.load(config_path = nil)
      # Default config from project root
      default_config_path = File.join(ROOT_PATH, 'config.yml')

      # Determine which config file to use
      if config_path
        # Custom config path provided via -c flag
        user_config_path = File.expand_path(config_path)
      else
        # Default user config location
        user_config_path = DEFAULT_CONFIG_PATH
        config_dir = File.dirname(user_config_path)

        # Ensure default config directory exists
        Dir.mkdir(config_dir) unless Dir.exist?(config_dir)

        # Copy default config to user config if it doesn't exist
        unless File.exist?(user_config_path)
          FileUtils.cp(default_config_path, user_config_path)
        end
      end

      # Load the config file
      config = YAML.safe_load(File.read(user_config_path))

      # Expand ~ in database_path
      if config['database_path']
        config['database_path'] = config['database_path'].gsub('~', Dir.home)
      end

      config
    end
  end
end
