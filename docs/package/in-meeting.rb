cask "in-meeting" do
  version "1.0.0"
  sha256 "a80840aa859006b9c8d57cd2e06e3cc41939045f937e8a763fbd65ed024d7719"

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