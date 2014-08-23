#!/usr/bin/env bash
# Author: Conor Schutzman <conor@mac.com>
ConsoleUser=$(stat -f %Su "/dev/console")
MAUprefs="/Users/$ConsoleUser/Library/Preferences/com.microsoft.autoupdate2.plist"
[[ "$(defaults read "$MAUprefs" HowToCheck | grep -c Manual)" -ne 1 ]] && defaults write "$MAUprefs" HowToCheck Manual
exit 0