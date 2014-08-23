#!/usr/bin/env bash
# Script Title: iCloud Keychain Checker 20140514
# Author: Conor Schutzman <conor@mac.com>
ConsoleUser=$(stat -f %Su '/dev/console')
KeychainPrefs="/Users/$ConsoleUser/Library/Preferences/MobileMeAccounts.plist"
KeychainStatus(){ "/usr/libexec/PlistBuddy" -c "Print Accounts:0:Services" "$KeychainPrefs" | grep -a1 KEYCHAIN_SYNC | grep $1; }
[[ "$ConsoleUser" = "root" ]] && exit 0
if [[ "$(sw_vers -productVersion | awk -F. '{print $2}')" -ge 9 ]] && [[ -e "$KeychainPrefs" ]] && [[ $(KeychainStatus true) -gt 0 ]]; then
	echo "<result>1</result>"
else
	echo "<result>0</result>"
fi
exit 0