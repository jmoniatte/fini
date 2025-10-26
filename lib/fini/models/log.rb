class Log < Sequel::Model
  # Create a log from a raw message string
  def self.create_from_message(message)
    parsed = parse_message(message)

    create(
      message: message,
      text: parsed[:text],
      activity: parsed[:activity],
      scope: parsed[:scope],
      duration: parsed[:duration],
      created_at: parsed[:timestamp]
    )
  end

  # Parse a message to extract components
  def self.parse_message(message)
    duration = extract_duration(message)
    scope = extract_scope(message)
    activity = extract_activity(message)

    # Remove duration and scope from the text to get clean description
    clean_text = message.dup
    clean_text.gsub!(/@\d+(?:\.\d+)?(?:h|m|hours?|minutes?)\b/, '')
    clean_text.gsub!(/#\w+/, '')
    clean_text.strip!

    {
      text: clean_text,
      activity: activity,
      duration: duration,
      scope: scope,
      timestamp: Time.now
    }
  end

  def to_s
    text
  end

  # Extract duration from message (e.g., @2h, @30m)
  def self.extract_duration(message)
    match = message.match(/@(\d+(?:\.\d+)?)(h|m|hours?|minutes?)/)
    return nil unless match

    value = match[1].to_f
    unit = match[2]

    case unit
    when 'h', 'hour', 'hours'
      value * 60 # convert to minutes
    when 'm', 'minute', 'minutes'
      value
    end
  end

  # Extract scope from message (e.g., #scope) - only first scope
  def self.extract_scope(message)
    match = message.match(/#(\w+)/)
    match ? match[1] : nil
  end

  # Extract activity from message (simple keyword matching)
  def self.extract_activity(message)
    activities = %w[meeting coding writing research reviewing planning testing debugging documenting call email]

    first_word = message.split.first&.downcase
    return first_word if activities.include?(first_word)

    nil
  end
end
