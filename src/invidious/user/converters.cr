module Invidious::User::Converters
  extend self

  # Named themes: value of the dark_mode preference => color scheme it builds on
  THEMES = {
    "catppuccin-latte" => "light",
  }

  def convert_theme(theme)
    case theme
    when "true"
      "dark"
    when "false"
      "light"
    when "light", "dark"
      theme
    else
      theme && THEMES.has_key?(theme) ? theme : nil
    end
  end

  # Returns the theme if it is a known dark_mode value, "" (auto) otherwise
  def validate_theme(theme : String) : String
    case theme
    when "light", "dark"
      theme
    else
      THEMES.has_key?(theme) ? theme : ""
    end
  end

  # Returns the color scheme of a dark_mode value: "light", "dark" or "" (auto)
  def theme_scheme(theme : String) : String
    THEMES[theme]? || validate_theme(theme)
  end
end
