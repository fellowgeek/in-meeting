cask "in-meeting" do
  version "1.0.0"
  sha256 "5246c7ffdd99c1de26b309d1e33b6ea29f2af92bd1592a5493b3052d44925b4b"

  url "https://github.com/fellowgeek/in-meeting/releases/download/v#{version}/in-meeting.dmg"
  name "in-meeting"
  desc "Lightweight privacy and home automation utility driven by macOS hardware observers"
  homepage "https://github.com/fellowgeek/in-meeting"

  depends_on macos: ">= :sonoma"

  app "in-meeting.app"
  # Target the internal executable directly to expose it to the CLI
  binary "#{appdir}/in-meeting.app/Contents/MacOS/in-meeting", target: "in-meeting"

  zap trash: [
    "~/Library/Application Support/in-meeting",
    "~/Library/Preferences/com.fellowgeek.In-Meeting.plist",
    "~/Library/Saved Application State/com.fellowgeek.In-Meeting.savedState",
  ]
end