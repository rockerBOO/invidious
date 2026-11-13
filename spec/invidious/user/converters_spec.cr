require "spectator"

# Invidious::User is a struct (see user.cr), declare it before converters.cr opens it
struct Invidious::User
end

require "../../../src/invidious/user/converters"

Spectator.configure do |config|
  config.fail_blank
  config.randomize
end

Spectator.describe Invidious::User::Converters do
  describe "#convert_theme" do
    it "converts legacy boolean values" do
      expect(Invidious::User::Converters.convert_theme("true")).to eq("dark")
      expect(Invidious::User::Converters.convert_theme("false")).to eq("light")
    end

    it "returns nil for empty values" do
      expect(Invidious::User::Converters.convert_theme("")).to be_nil
      expect(Invidious::User::Converters.convert_theme(nil)).to be_nil
    end

    it "keeps known themes" do
      expect(Invidious::User::Converters.convert_theme("light")).to eq("light")
      expect(Invidious::User::Converters.convert_theme("dark")).to eq("dark")
      expect(Invidious::User::Converters.convert_theme("catppuccin-latte")).to eq("catppuccin-latte")
    end

    it "returns nil for unknown themes" do
      expect(Invidious::User::Converters.convert_theme("unknown")).to be_nil
      expect(Invidious::User::Converters.convert_theme("dark\" onload=\"x")).to be_nil
    end
  end

  describe "#validate_theme" do
    it "accepts auto, light, dark and named themes" do
      {"", "light", "dark"}.each do |theme|
        expect(Invidious::User::Converters.validate_theme(theme)).to eq(theme)
      end

      Invidious::User::Converters::THEMES.each_key do |theme|
        expect(Invidious::User::Converters.validate_theme(theme)).to eq(theme)
      end
    end

    it "turns anything else into auto" do
      expect(Invidious::User::Converters.validate_theme("true")).to eq("")
      expect(Invidious::User::Converters.validate_theme("Dark")).to eq("")
      expect(Invidious::User::Converters.validate_theme("../default")).to eq("")
    end
  end

  describe "#theme_scheme" do
    it "returns the scheme of each theme" do
      expect(Invidious::User::Converters.theme_scheme("")).to eq("")
      expect(Invidious::User::Converters.theme_scheme("light")).to eq("light")
      expect(Invidious::User::Converters.theme_scheme("dark")).to eq("dark")
      expect(Invidious::User::Converters.theme_scheme("catppuccin-latte")).to eq("light")
      expect(Invidious::User::Converters.theme_scheme("unknown")).to eq("")
    end
  end
end
