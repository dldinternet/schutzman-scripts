#!/usr/bin/env bash

### HEADER
# Package Title: PWPolicy 4.1
# Date Modified: 2014-08-19 20:38:32
# Script Author: Conor Schutzman <conor@mac.com>

### VARIABLES
## DEFINITIONS
SoftwareTitle=PWPolicy
ScriptTitle=Screensaver
SectionTitle=Initialization
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y-%m-%d %H:%M:%S")
ConsoleUser=$(stat -f %Su '/dev/console')
CompliancePrefs="/Users/$ConsoleUser/Library/Preferences/com.compliance.plist"
EpochNow=$(date "+%s")
## DEFAULT VALUES
DefaultAskForPassword=1
DefaultPasswordDelay=5
DefaultIdleTime=600
DefaultIdleMinutes=$(expr $DefaultIdletime / 60)

### LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"

### FUNCTIONS
getIdleTime(){ sudo -u "$ConsoleUser" defaults -currentHost read com.apple.screensaver idleTime; }
getAskForPassword(){ sudo -u "$ConsoleUser" defaults read com.apple.screensaver askForPassword; }
getPasswordDelay(){ sudo -u "$ConsoleUser" defaults read com.apple.screensaver askForPasswordDelay; }
setIdleTime(){ SectionTitle=Policy; writeLog "Setting Preference: Start screen saver after $DefaultIdleMinutes Minutes"; sudo -u "$ConsoleUser" defaults -currentHost write com.apple.screensaver idleTime -int "$DefaultIdleTime"; }
setAskForPassword() { SectionTitle=Policy; writeLog "Setting Preference: Require password when waking from sleep or screen saver."; sudo -u "$ConsoleUser" defaults write com.apple.screensaver askForPassword -int "$DefaultAskForPassword"; }
setPasswordDelay() { SectionTitle=Policy; writeLog "Setting Preference: Require pasword $DefaultPasswordDelay seconds after sleep or screen saver begins."; sudo -u "$ConsoleUser" defaults -currentHost write com.apple.screensaver idleTime -int "$DefaultPasswordDelay"; }

### BODY
## POLICY CHECK
SectionTitle=Policy
# Check for need to create initial preferences.
sudo -u "$ConsoleUser" defaults read com.apple.screensaver >> "/dev/null" 2>&1
if [[ "$?" = 0 ]]; then
	# Require password prompt when exiting from screensaver.
	[[ "$(getAskForPassword)" = "$DefaultAskForPassword" ]] || setAskForPassword
	# Allow for more shorter (more secure) then default delay before asking for password.
	[[ "$(getPasswordDelay)" -gt "$DefaultPasswordDelay" ]] && setPasswordDelay
	[[ -z "$(getPasswordDelay)" ]] && setPasswordDelay
# If no prefs are found, set the default values
else
	writeLog "Existing user preferences not found, creating them."
	setPasswordDelay
	setAskForPassword
fi
if [[ -z "$(getIdleTime)" ]]; then
	writeLog "Existing currentHost preferences not found, creating them."
	setIdleTime
fi
## DEFER CHECK
SectionTitle=Defer
# Allow for a shorter (more secure) screen saver activation time.
if [[ "$(getIdleTime)" -gt "$DefaultIdleTime" ]]; then
	# Check if there is existing deferral.
	DeferEpoch="$(defaults read "$CompliancePrefs" SSDeferEpoch)"
	# If no existing deferral, initiate one
	if [[ -z "$DeferEpoch" ]]; then
		writeLog "Initiating one hour deferral."
		defaults write "$CompliancePrefs" SSDeferEpoch "$EpochNow"
	else
		DeferTime=$(expr $EpochNow - $DeferEpoch)
		if [[ "$DeferTime" -gt 3600 ]]; then
			writeLog "One hour deferral complete."
			defaults delete "$CompliancePrefs" SSDeferEpoch
			setIdleTime
		fi
	fi
fi
## AUTOMATIC LOGIN
SectionTitle=AutoLogin
# If auto login setting found, disable it.
if [[ ! -z "$(defaults read /Library/Preferences/com.apple.loginwindow.plist autoLoginUser)" ]]; then
	writeLog "Disabling automatic login."
	defaults delete "/Library/Preferences/com.apple.loginwindow" autoLoginUser
fi
## COMPLIANCE CHECK
SectionTitle=CompliancePrefs
# If Complaince prefs exist, toggle that screensaver policy has been ran, and write default values for later reference.
if [[ -e "$CompliancePrefs" ]]; then
	defaults write "$CompliancePrefs" Screensaver -bool true
	defaults write "$CompliancePrefs" PasswordDelay "$DefaultPasswordDelay"
	defaults write "$CompliancePrefs" Idletime "$DefaultIdletime"
	defaults write "$CompliancePrefs" AskForPassword "$DefaultAskForPassword"
	[[ "$(stat -f %Su "$CompliancePrefs")" = "$ConsoleUser" ]] || chown -v "$ConsoleUser" "$CompliancePrefs" >> "$LogFile"
	[[ "$(stat -f %g "$CompliancePrefs")" = "$(stat -f %g '/dev/console')" ]] || chgrp -v "$(stat -f %g '/dev/console')" "$CompliancePrefs" >> "$LogFile"
else
	writeLog "$CompliancePrefs not found."
fi
# Run Notif binary to force the refresh of preference changes.
if [[ -e "$(dirname "$0")/notif" ]]; then
	"$(dirname "$0")/notif"
else
	writeLog "$(dirname "$0")/notif not found, exiting."
	ls -la "$(dirname "$0")" >> "$LogFile"
	exit 1
fi
## FOOTER
exit 0