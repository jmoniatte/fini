module Utilities
  # Returns remaining string and extracted substring
  def self.extract_substring(string, pattern)
    extracted = string&.[](pattern)
    remaining = string&.sub(pattern, '')

    [remaining&.strip, extracted&.strip]
  end
end
