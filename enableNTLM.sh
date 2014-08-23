#!/usr/bin/env bash
# Script Title: Firefox Enable NTLM
# Author: Conor Schutzman <cschutzm@cisco.com>
ConsoleUser=$(stat -f %Su "/dev/console")
[[ $ConsoleUser = "root" ]] && exit 0
FirefoxFound=$(mdfind -onlyin /Applications -name Firefox | grep -c Firefox)
[[ $FirefoxFound < 1 ]] && exit 0
FirefoxLocation=$(mdfind -onlyin /Applications -name Firefox | head -n 1)
[[ -d $FirefoxLocation ]] || exit 0
FirefoxVersion=$(defaults read "$FirefoxLocation/Contents/Info.plist" CFBundleShortVersionString | awk -F. '{print $1}')
[[ "$FirefoxVersion" < 30 ]] && exit 0
ProfileFolder="/Users/$ConsoleUser/Library/Application Support/Firefox"
DefaultProfile=$(cat "$ProfileFolder/profiles.ini" | grep "Path=" | awk -F= '{print $2}')
NTLMEnabled=$(cat "$ProfileFolder/$DefaultProfile/prefs.js" | grep -c "allow-insecure-ntlm-v1")
[[ "$NTLMEnabled" > 0 ]] && exit 0
echo 'user_pref("network.negotiate-auth.allow-insecure-ntlm-v1", true);' >> "$ProfileFolder/$DefaultProfile/prefs.js"
echo "Modifying $FirefoxLocation v$FirefoxVersion"
echo "NTLM v1 enabled on profile $DefaultProfile"
exit 0