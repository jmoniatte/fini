module Fini
  module Config
    # Load configuration with user overrides
    def self.load
      # Ensure config directory exists
      config_dir = File.expand_path('~/.config/fini')
      Dir.mkdir(config_dir) unless Dir.exist?(config_dir)

      # Load default config from gem
      default_config_path = File.join(ROOT_PATH, 'config.yml')
      default_config = YAML.safe_load(File.read(default_config_path))

      # Load user config if it exists
      user_config_path = File.join(config_dir, 'config.yml')
      user_config = if File.exist?(user_config_path)
                      YAML.safe_load(File.read(user_config_path)) || {}
                    else
                      {}
                    end

      # Merge user config over default config (deep merge for nested hashes)
      merged_config = deep_merge(default_config, user_config)

      # Expand ~ in database path
      if merged_config['database']
        merged_config['database'] = merged_config['database'].gsub('~', Dir.home)
      end

      merged_config
    end

    # Deep merge two hashes
    def self.deep_merge(base, override)
      base.merge(override) do |_key, base_val, override_val|
        if base_val.is_a?(Hash) && override_val.is_a?(Hash)
          deep_merge(base_val, override_val)
        else
          override_val
        end
      end
    end
  end
end
