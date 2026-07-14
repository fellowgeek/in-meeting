cask "in-meeting" do
  version "1.0.1"
  sha256 "fc9049d149d85d3a0ea780f9d147ff7c5fc98df06332f49c7044fcbbe598871d"

  url "https://github.com/fellowgeek/in-meeting/releases/download/v#{version}/in-meeting.dmg"
  name "in-meeting"
  desc "Lightweight privacy and home automation utility driven by macOS hardware observers"
  homepage "https://github.com/fellowgeek/in-meeting"

  depends_on macos: :sonoma

  app "In Meeting.app"

  zap trash: [
    "~/Library/Application Support/in-meeting",
    "~/Library/Preferences/com.fellowgeek.In-Meeting.plist",
    "~/Library/Saved Application State/com.fellowgeek.In-Meeting.savedState",
  ]
end