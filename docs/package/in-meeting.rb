cask "in-meeting" do
  version "1.1.0"
  sha256 "cc530a9d5494b925e003810b75d5b86c9dfb9baea7f043dafc00ff861f53f884"

  url "https://github.com/fellowgeek/in-meeting/releases/download/v#{version}/in-meeting.dmg"
  name "in-meeting"
  desc "Lightweight privacy and home automation utility driven by macOS hardware observers"
  homepage "https://github.com/fellowgeek/in-meeting"

  depends_on macos: :sonoma

  app "In Meeting.app"

  zap trash: [
    "~/.in-meeting",
    "~/Library/Application Support/in-meeting",
    "~/Library/Preferences/com.fellowgeek.In-Meeting.plist",
    "~/Library/Saved Application State/com.fellowgeek.In-Meeting.savedState",
  ]
end