module Utilities
  # Returns remaining string and extracted substring
  def self.extract_substring(string, pattern)
    extracted = string&.[](pattern)
    remaining = string&.sub(pattern, '')

    [remaining&.strip, extracted&.strip]
  end

  def self.duration_string(minutes)
    return "0m" if minutes.to_i == 0

    hours = minutes / 60
    mins = minutes % 60

    if hours > 0 && mins > 0
      format("%<hours>dh%<mins>02d", hours: hours, mins: mins)
    elsif hours > 0
      "#{hours}h"
    else
      "#{mins}m"
    end
  end
end
