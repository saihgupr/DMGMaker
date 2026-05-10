#!/bin/bash
APP="/Applications/DMG Maker.app"

if [ ! -d "$APP" ]; then
    osascript -e 'display dialog "DMG Maker.app was not found in your Applications folder.\n\nPlease drag DMG Maker.app to Applications first, then run this script again." buttons {"OK"} default button "OK" with icon stop with title "DMG Maker - Fix Security"'
    exit 1
fi

xattr -cr "$APP"

osascript -e 'display dialog "DMG Maker is now unblocked!\n\nYou can now open it normally." buttons {"OK"} default button "OK" with icon note with title "DMG Maker - Fix Security"'
