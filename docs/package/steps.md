### Create a DMG
```
hdiutil create -volname "In Meeting" -srcfolder /path/to/In\ Meeting.app -ov -format UDZO in-meeting.dmg
```

### Generate the SHA-256 Hash
```
shasum -a 256 /path/to/in-meeting.dmg
```