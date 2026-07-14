### Create a DMG
```
hdiutil create -volname "In Meeting" -srcfolder ./In\ Meeting.app -ov -format UDZO in-meeting.dmg
```

### Generate the SHA-256 Hash
```
shasum -a 256 ./in-meeting.dmg
```