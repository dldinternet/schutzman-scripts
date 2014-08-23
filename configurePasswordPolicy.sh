#!/usr/bin/env bash

### HEADER
# Package Title: PWPolicy 4.1
# Date Modified: 2014-08-15 12:27:48
# Script Author: Conor Schutzman <conor@mac.com>

### VARIABLES
## DEFINITIONS
SoftwareTitle=PWPolicy
ScriptTitle=Password
SectionTitle=Initialization
LogFile="/Library/Logs/$SoftwareTitle.log"
TimeStamp=$(date "+%Y-%m-%d %H:%M:%S")
ConsoleUser=$(stat -f %Su '/dev/console')
CompliancePrefs="/Users/$ConsoleUser/Library/Preferences/com.compliance.plist"
ArchivePrefs="/Users/$ConsoleUser/Library/Backup/com.oldpwpolicy.plist"
## DEFAULT VALUES
NeedPolicy=0
NeedPrefs=0
DefaultRequiresNumeric=1
DefaultRequiresAlpha=1
DefaultMinCharacters=8
DefaultSecsToLog=0
DefaultDefers=5
DefaultPol=0

### LOGGING
writeLog(){ echo "[$(date "+%Y-%m-%d %H:%M:%S")] [$ConsoleUser] [$ScriptTitle] [$SectionTitle] $1" >> "$LogFile"; }
[[ -e "$(dirname "$LogFile")" ]] || mkdir -p -m 775 "$(dirname "$LogFile")"
[[ "$(stat -f%z "$LogFile")" -ge 1000000 ]] && rm -rf "$LogFile"
[[ -d "$(dirname "$ArchivePrefs")" ]] || mkdir -p "$(dirname "$ArchivePrefs")"

### FUNCTIONS
archiveRequiresNumeric(){ defaults write "$ArchivePrefs" RequiresNumeric "$requiresNumeric"; }
archiveRequiresAlpha(){ defaults write "$ArchivePrefs" RequiresAlpha "$requiresAlpha"; }
archiveMinCharacters(){ defaults write "$ArchivePrefs" MinCharacters "$minChars"; }
getPWReset(){ defaults read "$CompliancePrefs" PWReset; }
getRequiresNumeric(){ defaults read "$CompliancePrefs" RequiresNumeric; }
getRequiresAlpha(){ defaults read "$CompliancePrefs" RequiresAlpha; }
getMinCharacters(){ defaults read "$CompliancePrefs" MinCharacters; }
setPWResetOff(){ defaults write "$CompliancePrefs" PWReset -bool false; }
setPWResetOn(){ SectionTitle=Policy; writeLog "Password reset will be required."; defaults write "$CompliancePrefs" PWReset -bool true; }
setRequiresNumeric(){ SectionTitle=Policy; writeLog "Setting Preference: Requires numeric characters."; defaults write "$CompliancePrefs" RequiresNumeric "$DefaultRequiresNumeric"; }
setRequiresAlpha(){ SectionTitle=Policy; writeLog "Setting Preference: Requires alpha characters."; defaults write "$CompliancePrefs" RequiresAlpha "$DefaultRequiresAlpha"; }
setMinCharacters(){ SectionTitle=Policy; writeLog "Setting Preference: Minimum characters."; defaults write "$CompliancePrefs" MinCharacters "$DefaultMinCharacters"; }
setPol(){ SectionTitle=Policy; writeLog "Policy will need to be reset."; defaults write "$CompliancePrefs" Pol "requiresNumeric=$DefaultRequiresNumeric requiresAlpha=$DefaultRequiresAlpha minChars=$DefaultMinCharacters"; }
setSecsToLog(){ defaults write "$CompliancePrefs" SecsToLog "$DefaultSecsToLog"; }
setDefers(){ defaults write "$CompliancePrefs" Defers "$DefaultDefers"; }

### BODY
## DEFAULTS
setPWResetOff
## USER CHECKS
SectionTitle=User
# Exit if Root
if [[ "$(stat -f %u '/dev/console')" = 0 ]]; then
	writeLog "No console user, exiting."
	exit 0
fi
# Exit if bound to AD
if [[ "$(dsmemberutil checkmembership -U "$ConsoleUser" -G netaccounts | grep -c "user is a member of the group")" -gt 0 ]]; then
	[[ "$(cat "$LogFile" | grep -c "Bound to AD, exiting.")" = 0  ]] && writeLog "Bound to AD, exiting."
	exit 0
fi
# Check if console user is an admin
if [[ "$(id "$ConsoleUser" | grep -c 80)" -lt 1 ]]; then
	[[ "$(cat "$LogFile" | grep -c "User is not an admin.")" = 0  ]] && writeLog "User is not an admin."
fi
## COMPLIANCE PLIST
SectionTitle=Compliance
if [[ ! -e "$CompliancePrefs" ]]; then
	setPWResetOn
	setRequiresNumeric
	setRequiresAlpha
	setMinCharacters
	setPol
	setSecsToLog
	setDefers
fi
## POLICY
SectionTitle=Policy
eval $(pwpolicy -u $ConsoleUser -getpolicy | grep = | awk '{for (i = 1; i <= NF; i++) print $i}')
if [[ "$requiresNumeric" != "$DefaultRequiresNumeric" ]]; then
	setPWResetOn
	archiveRequiresNumeric
	setRequiresNumeric
fi
if [[ "$requiresAlpha" != "$DefaultRequiresAlpha" ]]; then
	setPWResetOn
	archiveRequiresAlpha
	setRequiresAlpha
fi
if [[ "$minChars" -lt "$DefaultMinCharacters" ]]; then
	setPWResetOn
	archiveMinCharacters
	setMinCharacters
fi
## CLEAN UP
SectionTitle=CleanUp
# Fix Permissions
if [[ -e "$ArchivePrefs" ]]; then
	[[ "$(stat -f %Su "$ArchivePrefs")" = "$ConsoleUser" ]] || chown -v "$ConsoleUser" "$ArchivePrefs" >> "$LogFile"
	[[ "$(stat -f %g "$ArchivePrefs")" = "$(stat -f %g '/dev/console')" ]] || chgrp -v "$(stat -f %g '/dev/console')" "$ArchivePrefs" >> "$LogFile"
fi
[[ "$(stat -f %Su "$CompliancePrefs")" = "$ConsoleUser" ]] || chown -v "$ConsoleUser" "$CompliancePrefs" >> "$LogFile"
[[ "$(stat -f %g "$CompliancePrefs")" = "$(stat -f %g '/dev/console')" ]] || chgrp -v "$(stat -f %g '/dev/console')" "$CompliancePrefs" >> "$LogFile"
if [[ $(getPWReset) = 1 ]]; then
	# Kill AnyConnect
	if [[ -e "/opt/cisco/anyconnect/bin/vpn" ]]; then
		"/opt/cisco/anyconnect/bin/vpn" disconnect
	fi
	if [[ "$(ps -ax | grep -c AnyConnect)" -gt 1 ]]; then
		writeLog "Quitting AnyConnect"
		kill -9 "$(ps -ax | grep AnyConnect | head -n 1 | awk '{print $1}')"
	fi
	# Pass policy to App
	setPol
	# Do something
	echo "Do something on policy failure."
fi

## FOOTER
exit 0